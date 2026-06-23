import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/farmer/data/pickup_point_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/pickup_point_service.dart';

void main() {
  late AppDatabase database;
  late FakePickupPointRemote remote;
  late PickupPointRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakePickupPointRemote();
    repository = PickupPointRepository.forTesting(
      database: database,
      remote: remote,
    );
    SessionManager().clearSession();
    SessionManager().setSession(
      token: 'test-token',
      username: 'farmer_test',
      rol: 'TEST',
    );
  });

  tearDown(() async {
    await database.close();
    SessionManager().clearSession();
  });

  test('stores remote pickup points and serves the local cache', () async {
    remote.points = [_pointJson(id: 'remote-point')];

    await repository.refreshFromRemote();
    final cached = await repository.watchPickupPoints().first;

    expect(cached, hasLength(1));
    expect(cached.single.pickupPoint.name, 'Mercado Central');
    expect(cached.single.syncState, EntitySyncState.synced);
    expect(await repository.getLastSyncedAt(), isNotNull);
  });

  test(
    'compacts offline create and edit into one idempotent request',
    () async {
      final localId = await repository.createPickupPoint(_pointPayload());
      await repository.updatePickupPoint(localId, {
        ..._pointPayload(),
        'name': 'Mercado Central editado',
      });

      SessionManager().setSession(rol: 'AGRICULTOR');
      await repository.syncPending(includeFailed: true);
      await repository.syncPending(includeFailed: true);

      expect(remote.createCalls, 1);
      expect(remote.createdClientIds, [localId]);
      expect(remote.createdNames, ['Mercado Central editado']);
      final cached = await repository.watchPickupPoints().first;
      expect(cached.single.syncState, EntitySyncState.synced);

      final operations = await database.select(database.syncOperations).get();
      expect(operations, hasLength(1));
      expect(operations.single.state, SyncOperationState.synced.value);
    },
  );

  test('keeps a rejected operation as a conflict', () async {
    await repository.createPickupPoint(_pointPayload());
    remote.createError = Exception('Error al crear punto: 400 fecha vencida');
    SessionManager().setSession(rol: 'AGRICULTOR');

    await repository.syncPending(includeFailed: true, force: true);

    final cached = await repository.watchPickupPoints().first;
    expect(cached.single.syncState, EntitySyncState.conflict);
    final operation = await database
        .select(database.syncOperations)
        .getSingle();
    expect(operation.state, SyncOperationState.conflict.value);
    expect(operation.lastError, contains('fecha vencida'));
  });
}

Map<String, dynamic> _pointPayload() {
  final delivery = DateTime.now().add(const Duration(days: 5));
  final deadline = DateTime.now().add(const Duration(days: 3));
  String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
  return {
    'name': 'Mercado Central',
    'address': 'Av. Principal 123',
    'deliveryDate': date(delivery),
    'availableFrom': '10:00:00',
    'availableTo': '12:00:00',
    'orderDeadlineDate': date(deadline),
    'orderDeadlineTime': '15:00:00',
    'status': 'ACTIVE',
  };
}

Map<String, dynamic> _pointJson({required String id}) => {
  ..._pointPayload(),
  'id': id,
  'farmerUsername': 'farmer_test',
};

class FakePickupPointRemote implements PickupPointRemoteDataSource {
  List<Map<String, dynamic>> points = [];
  Object? createError;
  int createCalls = 0;
  final List<String> createdClientIds = [];
  final List<String> createdNames = [];

  @override
  Future<List<Map<String, dynamic>>> listarRaw() async => points;

  @override
  Future<Map<String, dynamic>> crearRaw(Map<String, dynamic> payload) async {
    createCalls++;
    if (createError != null) throw createError!;
    createdClientIds.add(payload['clientId'].toString());
    createdNames.add(payload['name'].toString());
    return {
      ...payload,
      'id': payload['clientId'],
      'farmerUsername': 'farmer_test',
    };
  }

  @override
  Future<Map<String, dynamic>> editarRaw(
    String id,
    Map<String, dynamic> payload,
  ) async => {...payload, 'id': id, 'farmerUsername': 'farmer_test'};

  @override
  Future<void> eliminar(String id) async {}
}
