import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_order_model.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_order_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/farmer_order_service.dart';

void main() {
  late AppDatabase database;
  late FakeFarmerOrderRemote remote;
  late FarmerOrderRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeFarmerOrderRemote();
    repository = FarmerOrderRepository.forTesting(
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

  test('stores order groups and serves them from the local database', () async {
    remote.groups = [_groupJson(status: 'CONFIRMED')];

    await repository.refreshFromRemote();
    final cached = await repository.watchGroups().first;

    expect(cached, hasLength(1));
    expect(cached.single.group.nombrePunto, 'Mercado Central');
    expect(cached.single.group.state, OrderGroupState.porPreparar);
    expect(cached.single.syncState, EntitySyncState.synced);
  });

  test(
    'marks prepared offline and replaces the changed group key on sync',
    () async {
      remote.groups = [_groupJson(status: 'CONFIRMED')];
      await repository.refreshFromRemote();
      final original = (await repository.watchGroups().first).single.group;

      await repository.markPrepared(original.id, ['sub-1']);
      final pending = await repository.watchGroups().first;
      expect(pending.single.group.state, OrderGroupState.seleccionandoDespacho);
      expect(pending.single.syncState, EntitySyncState.pending);

      remote.preparedSnapshot = [_groupJson(status: 'PREPARED')];
      SessionManager().setSession(rol: 'AGRICULTOR');
      await repository.syncPending(includeFailed: true);
      await repository.syncPending(includeFailed: true);

      expect(remote.prepareCalls, 1);
      final synced = await repository.watchGroups().first;
      expect(synced, hasLength(1));
      expect(synced.single.group.id, contains('PREPARED'));
      expect(synced.single.syncState, EntitySyncState.synced);
    },
  );

  test(
    'keeps preparation as conflict when backend rejects the state',
    () async {
      remote.groups = [_groupJson(status: 'CONFIRMED')];
      await repository.refreshFromRemote();
      final group = (await repository.watchGroups().first).single.group;
      await repository.markPrepared(group.id, ['sub-1']);
      remote.prepareError = Exception('Error al marcar preparado: 400 estado');
      SessionManager().setSession(rol: 'AGRICULTOR');

      await repository.syncPending(includeFailed: true, force: true);

      final cached = await repository.watchGroups().first;
      expect(cached.single.syncState, EntitySyncState.conflict);
      final operation = await database
          .select(database.syncOperations)
          .getSingle();
      expect(operation.state, SyncOperationState.conflict.value);
    },
  );
}

Map<String, dynamic> _groupJson({required String status}) {
  final groupKey = 'farmer_test:PICKUP:point-1:2026-07-10:$status';
  return {
    'groupKey': groupKey,
    'deliveryMethod': 'PICKUP',
    'pickupPointName': 'Mercado Central',
    'destinationAddress': 'Av. Principal 123',
    'pickupSchedule': 'Viernes 10/07/2026 • 10:00 - 12:00',
    'pickupFrom': '10:00:00',
    'pickupTo': '12:00:00',
    'status': status,
    'orderCount': 1,
    'total': 20.0,
    'itemsToPrepare': status == 'CONFIRMED'
        ? [
            {'productName': 'Papa', 'saleFormat': 'KILO', 'quantity': 2},
          ]
        : [],
    'customerOrders': [
      {
        'subOrderId': 'sub-1',
        'customerUsername': 'customer',
        'customerName': 'Cliente Uno',
        'total': 20.0,
        'items': [
          {
            'productName': 'Papa',
            'saleFormat': 'KILO',
            'quantity': 2,
            'unitPrice': 10.0,
          },
        ],
      },
    ],
    'subOrders': [
      {
        'id': 'sub-1',
        'customerUsername': 'customer',
        'customerName': 'Cliente Uno',
        'deliveryMethod': 'PICKUP',
        'paymentMethod': 'CASH',
        'status': status,
        'productsTotal': 20.0,
        'deliveryCost': 0.0,
        'total': 20.0,
        'items': [
          {
            'productName': 'Papa',
            'saleFormat': 'KILO',
            'quantity': 2,
            'unitPrice': 10.0,
          },
        ],
      },
    ],
  };
}

class FakeFarmerOrderRemote implements FarmerOrderRemoteDataSource {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> preparedSnapshot = [];
  Object? prepareError;
  int prepareCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> listarGruposRaw() async => groups;

  @override
  Future<List<Map<String, dynamic>>> marcarPreparadoRaw(
    List<String> subOrderIds,
  ) async {
    prepareCalls++;
    if (prepareError != null) throw prepareError!;
    return preparedSnapshot;
  }
}
