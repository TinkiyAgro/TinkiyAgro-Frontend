import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/image_store.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_product_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/farmer_product_service.dart';

void main() {
  late AppDatabase database;
  late FakeProductRemote remote;
  late FarmerProductRepository repository;
  late Directory temporaryDirectory;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeProductRemote();
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'tinkiyagro_test',
    );
    repository = FarmerProductRepository.forTesting(
      database: database,
      remote: remote,
      images: FakeImageStore(temporaryDirectory),
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
    await temporaryDirectory.delete(recursive: true);
    SessionManager().clearSession();
  });

  test(
    'stores remote products and serves them from the local database',
    () async {
      remote.products = [_productJson(id: 'remote-1')];

      await repository.refreshFromRemote();
      final cached = await repository.watchProducts().first;

      expect(cached, hasLength(1));
      expect(cached.single.product.nombre, 'Papa amarilla');
      expect(cached.single.syncState, EntitySyncState.synced);
      expect(await repository.getLastSyncedAt(), isNotNull);
    },
  );

  test('retries an offline creation once without duplicating it', () async {
    final source = File('${temporaryDirectory.path}/source.jpg');
    await source.writeAsBytes([1, 2, 3]);

    final localId = await repository.createProduct(
      _productPayload(),
      imageFile: source,
    );
    final pending = await repository.watchProducts().first;
    expect(pending.single.product.id, localId);
    expect(pending.single.syncState, EntitySyncState.pending);

    await repository.updateProduct(localId, {
      ..._productPayload(),
      'name': 'Papa amarilla editada',
    });

    SessionManager().setSession(rol: 'AGRICULTOR');
    await repository.syncPending(includeFailed: true);
    await repository.syncPending(includeFailed: true);

    expect(remote.createCalls, 1);
    expect(remote.createdClientIds, [localId]);
    expect(remote.createdNames, ['Papa amarilla editada']);
    final synced = await repository.watchProducts().first;
    expect(synced.single.syncState, EntitySyncState.synced);

    final operations = await database.select(database.syncOperations).get();
    expect(operations, hasLength(1));
    expect(operations.single.state, SyncOperationState.synced.value);
  });

  test('sends the downloaded version when updating stock', () async {
    remote.products = [_productJson(id: 'remote-1', version: 4)];
    await repository.refreshFromRemote();

    await repository.updateProduct('remote-1', {
      ..._productPayload(),
      'saleFormats': [
        {...(_productPayload()['saleFormats'] as List).single, 'stock': 12},
      ],
    });

    SessionManager().setSession(rol: 'AGRICULTOR');
    await repository.syncPending(force: true);

    expect(remote.updatedVersions, [4]);
    final cached = (await repository.watchProducts().first).single;
    expect(cached.product.version, 5);
    expect(cached.syncState, EntitySyncState.synced);
  });

  test('keeps an obsolete stock update as conflict', () async {
    remote.products = [_productJson(id: 'remote-1', version: 2)];
    await repository.refreshFromRemote();
    await repository.updateProduct('remote-1', _productPayload());
    remote.updateError = Exception('Error al modificar producto: 409');
    SessionManager().setSession(rol: 'AGRICULTOR');

    await repository.syncPending(force: true);

    final cached = (await repository.watchProducts().first).single;
    expect(cached.syncState, EntitySyncState.conflict);
  });

  test('a new edit retries and replaces a previous conflict', () async {
    remote.products = [_productJson(id: 'remote-1', version: 2)];
    await repository.refreshFromRemote();
    await repository.updateProduct('remote-1', {
      ..._productPayload(),
      'name': 'Nombre temporal',
    });
    remote.updateError = Exception('Error al modificar producto: 409');
    SessionManager().setSession(rol: 'AGRICULTOR');
    await repository.syncPending(force: true);

    remote.updateError = null;
    remote.products = [_productJson(id: 'remote-1', version: 3)];
    SessionManager().setSession(rol: 'TEST');
    await repository.updateProduct('remote-1', _productPayload());
    SessionManager().setSession(rol: 'AGRICULTOR');
    await repository.syncPending(force: true);

    final cached = (await repository.watchProducts().first).single;
    expect(cached.product.nombre, 'Papa amarilla');
    expect(cached.syncState, EntitySyncState.synced);
    expect(remote.updatedVersions.last, 3);
    expect(await repository.watchPendingCount().first, 0);
  });

  test('serializes rapid edits and refreshes the optimistic version', () async {
    remote.products = [_productJson(id: 'remote-1', version: 4)];
    await repository.refreshFromRemote();
    await repository.updateProduct('remote-1', {
      ..._productPayload(),
      'name': 'Nombre temporal',
      'category': 'FRUTAS',
    });
    remote.updateGate = Completer<void>();
    remote.updateStarted = Completer<void>();
    SessionManager().setSession(rol: 'AGRICULTOR');

    final firstSync = repository.syncPending(force: true);
    await remote.updateStarted!.future;
    await repository.updateProduct('remote-1', _productPayload());
    remote.updateGate!.complete();
    await firstSync;

    final cached = (await repository.watchProducts().first).single;
    expect(remote.updatedVersions, [4, 5]);
    expect(cached.product.nombre, 'Papa amarilla');
    expect(cached.product.categoria, 'Tubérculos');
    expect(cached.syncState, EntitySyncState.synced);
    expect(await repository.watchPendingCount().first, 0);
  });

  test('deleting a conflicted product removes stale operations', () async {
    remote.products = [_productJson(id: 'remote-1', version: 2)];
    await repository.refreshFromRemote();
    await repository.updateProduct('remote-1', _productPayload());
    remote.updateError = Exception('Error al modificar producto: 409');
    SessionManager().setSession(rol: 'AGRICULTOR');
    await repository.syncPending(force: true);

    await repository.deleteProduct('remote-1');
    await repository.syncPending(force: true);

    expect(await repository.watchProducts().first, isEmpty);
    expect(await repository.watchPendingCount().first, 0);
    expect(remote.deleteCalls, 1);
  });

  test('refresh removes orphaned product conflicts from the counter', () async {
    await database
        .into(database.syncOperations)
        .insert(
          SyncOperationsCompanion.insert(
            id: 'orphan-operation',
            idempotencyKey: 'orphan-operation',
            ownerUsername: 'farmer_test',
            role: 'AGRICULTOR',
            operationType: SyncOperationType.updateProduct.value,
            entityType: 'PRODUCT',
            entityLocalId: 'deleted-product',
            payloadJson: '{}',
            createdAt: DateTime.now(),
            state: SyncOperationState.conflict.value,
          ),
        );

    expect(await repository.watchPendingCount().first, 1);
    await repository.refreshFromRemote();
    expect(await repository.watchPendingCount().first, 0);
  });
}

Map<String, dynamic> _productPayload() => {
  'name': 'Papa amarilla',
  'category': 'TUBERCULOS',
  'saleFormats': [
    {
      'saleFormat': 'KILO',
      'price': 4.5,
      'stock': 20,
      'referenceUnitWeightKg': 0.3,
    },
  ],
};

Map<String, dynamic> _productJson({required String id, int version = 0}) => {
  ..._productPayload(),
  'id': id,
  'version': version,
  'imageUrl': '/images/papa.jpg',
  'status': 'DISPONIBLE',
  'averageRating': 0,
  'reviewCount': 0,
};

class FakeImageStore implements LocalImageStore {
  FakeImageStore(this.directory);

  final Directory directory;

  @override
  Future<String> preserve(File source, String localId) async {
    final target = File('${directory.path}/$localId.jpg');
    await source.copy(target.path);
    return target.path;
  }

  @override
  Future<void> deleteIfManaged(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class FakeProductRemote implements FarmerProductRemoteDataSource {
  List<Map<String, dynamic>> products = [];
  int createCalls = 0;
  final List<String> createdClientIds = [];
  final List<String> createdNames = [];
  final List<int> updatedVersions = [];
  Object? updateError;
  Completer<void>? updateStarted;
  Completer<void>? updateGate;
  int deleteCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> listarProductosRaw() async => products;

  @override
  Future<Map<String, dynamic>> agregarProductoRaw(
    Map<String, dynamic> datos, {
    required File imageFile,
  }) async {
    createCalls++;
    final id = datos['clientId'].toString();
    createdClientIds.add(id);
    createdNames.add(datos['name'].toString());
    return {
      ...datos,
      'id': id,
      'imageUrl': '/images/$id.jpg',
      'status': 'DISPONIBLE',
      'averageRating': 0,
      'reviewCount': 0,
    };
  }

  @override
  Future<void> eliminarProducto(String id) async {
    deleteCalls++;
  }

  @override
  Future<Map<String, dynamic>> modificarProductoRaw(
    String id,
    Map<String, dynamic> datos, {
    File? imageFile,
  }) async {
    if (updateError != null) throw updateError!;
    updateStarted?.complete();
    await updateGate?.future;
    updateStarted = null;
    updateGate = null;
    final version = datos['version'] as int? ?? 0;
    updatedVersions.add(version);
    return {...datos, 'id': id, 'version': version + 1};
  }
}
