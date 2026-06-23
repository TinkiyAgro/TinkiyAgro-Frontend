import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/courier/data/courier_delivery_repository.dart';
import 'package:tinkiyagro_app/features/courier/data/remote/courier_service.dart';

void main() {
  late AppDatabase database;
  late FakeCourierRemote remote;
  late CourierDeliveryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeCourierRemote();
    repository = CourierDeliveryRepository.forTesting(
      database: database,
      remote: remote,
    );
    _setCourier('courier_a');
  });

  tearDown(() async {
    await database.close();
    SessionManager().clearSession();
  });

  test('keeps assigned deliveries available after the backend fails', () async {
    remote.deliveries = [_deliveryJson(farmerName: 'Agricultor Uno')];
    await repository.refreshFromRemote();

    remote.error = Exception('Sin conexión al servidor.');
    await expectLater(repository.refreshFromRemote(), throwsException);
    final cached = await repository.watchDeliveries().first;

    expect(cached, hasLength(1));
    expect(cached.single.farmerName, 'Agricultor Uno');
    expect(cached.single.customers.single.clientName, 'Cliente Uno');
    expect(cached.single.customers.single.destinationAddress, contains('Lima'));
    expect(await repository.watchLastSyncedAt().first, isNotNull);
  });

  test('isolates equal group keys between different couriers', () async {
    remote.deliveries = [_deliveryJson(farmerName: 'Agricultor A')];
    await repository.refreshFromRemote();

    _setCourier('courier_b');
    remote.deliveries = [_deliveryJson(farmerName: 'Agricultor B')];
    await repository.refreshFromRemote();

    final courierB = await repository.watchDeliveries().first;
    expect(courierB.single.farmerName, 'Agricultor B');
    _setCourier('courier_a');
    final courierA = await repository.watchDeliveries().first;
    expect(courierA.single.farmerName, 'Agricultor A');
  });

  test('voluntary logout clears only the current courier cache', () async {
    remote.deliveries = [_deliveryJson(farmerName: 'Agricultor A')];
    await repository.refreshFromRemote();
    _setCourier('courier_b');
    remote.deliveries = [_deliveryJson(farmerName: 'Agricultor B')];
    await repository.refreshFromRemote();

    await repository.clearCurrentUserCache();
    expect(await repository.watchDeliveries().first, isEmpty);

    _setCourier('courier_a');
    expect(await repository.watchDeliveries().first, hasLength(1));
  });
}

void _setCourier(String username) {
  SessionManager().clearSession();
  SessionManager().setSession(
    token: 'test-token',
    username: username,
    rol: 'REPARTIDOR',
  );
}

Map<String, dynamic> _deliveryJson({required String farmerName}) => {
  'groupKey': 'farmer:PICKUP:destination:DISPATCHED',
  'deliveryMethod': 'DELIVERY',
  'farmerUsername': 'farmer',
  'farmerName': farmerName,
  'farmerProfileImageUrl': '',
  'farmerPhoneNumber': '999888777',
  'destinationAddress': 'Av. Principal 123',
  'status': 'DISPATCHED',
  'total': 32.0,
  'subOrders': [
    {
      'id': 'sub-1',
      'customerUsername': 'customer',
      'customerName': 'Cliente Uno',
      'deliveryMethod': 'DELIVERY',
      'paymentMethod': 'YAPE',
      'yapePhoneNumber': '988777666',
      'status': 'DISPATCHED',
      'deliveryCost': 2.0,
      'total': 32.0,
      'destination': {
        'address': 'Av. Principal 123',
        'district': 'Lima',
        'reference': 'Frente al parque',
      },
      'items': [
        {
          'productName': 'Papa',
          'saleFormat': 'KILO',
          'quantity': 3,
          'unitPrice': 10.0,
        },
      ],
    },
  ],
};

class FakeCourierRemote implements CourierRemoteDataSource {
  List<Map<String, dynamic>> deliveries = [];
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> listDeliveriesRaw() async {
    if (error != null) throw error!;
    return deliveries;
  }

  @override
  Future<Map<String, dynamic>> updateTrackingRaw(
    String subOrderId,
    Map<String, dynamic> payload,
  ) async {
    if (error != null) throw error!;
    return {'id': subOrderId, ...payload};
  }
}
