import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/courier/data/courier_tracking_repository.dart';
import 'package:tinkiyagro_app/features/courier/data/remote/courier_service.dart';

void main() {
  late AppDatabase database;
  late FakeTrackingRemote remote;
  late CourierTrackingRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeTrackingRemote();
    repository = CourierTrackingRepository.forTesting(
      database: database,
      remote: remote,
    );
    _setSession(role: 'TEST');
  });

  tearDown(() async {
    await database.close();
    SessionManager().clearSession();
  });

  test('keeps and syncs only the newest location per suborder', () async {
    final firstCapture = DateTime.parse('2026-06-22T10:00:00-05:00');
    final latestCapture = DateTime.parse('2026-06-22T10:05:00-05:00');

    await repository.recordLocation(
      subOrderId: 'sub-1',
      label: 'Primera posicion',
      latitude: -12.01,
      longitude: -77.01,
      capturedAt: firstCapture,
    );
    await repository.recordLocation(
      subOrderId: 'sub-1',
      label: 'Posicion mas reciente',
      latitude: -12.02,
      longitude: -77.02,
      capturedAt: latestCapture,
    );

    final queued =
        await (database.select(database.syncOperations)..where(
              (row) => row.operationType.equals(
                SyncOperationType.updateTracking.value,
              ),
            ))
            .get();
    expect(queued, hasLength(1));
    final payload =
        jsonDecode(queued.single.payloadJson) as Map<String, dynamic>;
    expect(payload['label'], 'Posicion mas reciente');
    expect(payload['latitude'], -12.02);
    expect(payload['capturedAt'], '2026-06-22T15:05:00.000Z');

    _setSession(role: 'REPARTIDOR');
    await repository.syncPending(force: true);

    expect(remote.trackingCalls, hasLength(1));
    expect(remote.trackingCalls.single['latitude'], -12.02);
    final status = (await repository.watchStatuses(['sub-1']).first).single;
    // SQLite stores the wall-clock value without retaining the UTC marker.
    expect(status.capturedAt, DateTime(2026, 6, 22, 10, 5));
    expect(status.syncState, EntitySyncState.synced);
    expect(status.syncedAt, isNotNull);
  });

  test('preserves rejected tracking as a visible conflict', () async {
    await repository.recordLocation(
      subOrderId: 'sub-1',
      label: 'En ruta',
      latitude: -12.01,
      longitude: -77.01,
    );
    remote.trackingError = Exception('HTTP 409: pedido reasignado');
    _setSession(role: 'REPARTIDOR');

    await repository.syncPending(force: true);

    final status = (await repository.watchStatuses(['sub-1']).first).single;
    expect(status.syncState, EntitySyncState.conflict);
    expect(status.lastError, contains('409'));
    final operation = await database
        .select(database.syncOperations)
        .getSingle();
    expect(operation.state, SyncOperationState.conflict.value);
  });
}

void _setSession({required String role}) {
  SessionManager().clearSession();
  SessionManager().setSession(
    token: 'test-token',
    username: 'courier-a',
    rol: role,
  );
}

class FakeTrackingRemote implements CourierRemoteDataSource {
  final List<Map<String, dynamic>> trackingCalls = [];
  Object? trackingError;

  @override
  Future<List<Map<String, dynamic>>> listDeliveriesRaw() async => [];

  @override
  Future<Map<String, dynamic>> updateTrackingRaw(
    String subOrderId,
    Map<String, dynamic> payload,
  ) async {
    if (trackingError != null) throw trackingError!;
    trackingCalls.add({'subOrderId': subOrderId, ...payload});
    return {'id': subOrderId, ...payload};
  }
}
