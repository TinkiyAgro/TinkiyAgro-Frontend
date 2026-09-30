import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/app_database.dart';
import '../../../core/offline/image_store.dart';
import '../../../core/offline/sync_types.dart';
import '../../../core/session_manager.dart';
import '../../catalog/data/product_model.dart';
import 'offline_farmer_product.dart';
import 'remote/farmer_product_service.dart';

class FarmerProductRepository {
  FarmerProductRepository._()
    : _db = AppDatabase.instance,
      _remote = FarmerProductService(),
      _images = const OfflineImageStore(),
      _uuid = const Uuid();

  FarmerProductRepository.forTesting({
    required AppDatabase database,
    required FarmerProductRemoteDataSource remote,
    required LocalImageStore images,
    Uuid uuid = const Uuid(),
  }) : _db = database,
       _remote = remote,
       _images = images,
       _uuid = uuid;

  static final FarmerProductRepository instance = FarmerProductRepository._();

  final AppDatabase _db;
  final FarmerProductRemoteDataSource _remote;
  final LocalImageStore _images;
  final Uuid _uuid;
  bool _syncing = false;
  Timer? _retryTimer;

  String get _owner {
    final session = SessionManager();
    final username =
        session.username ??
        (session.token == null
            ? null
            : SessionManager.decodeJwt(session.token!)?['sub']?.toString());
    if (username == null || username.isEmpty) {
      throw StateError('No hay un usuario autenticado para la cache offline.');
    }
    return username;
  }

  Stream<List<OfflineFarmerProduct>> watchProducts() {
    final owner = _owner;
    final query = _db.select(_db.cachedFarmerProducts)
      ..where((row) => row.ownerUsername.equals(owner) & row.isDeleted.not())
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
      (rows) => rows.map(_mapCachedProduct).toList(growable: false),
    );
  }

  Stream<int> watchPendingCount() {
    final owner = _owner;
    final count = _db.syncOperations.id.count();
    final query = _db.selectOnly(_db.syncOperations)
      ..addColumns([count])
      ..where(
        _db.syncOperations.ownerUsername.equals(owner) &
            _db.syncOperations.state.isIn([
              SyncOperationState.pending.value,
              SyncOperationState.failed.value,
              SyncOperationState.conflict.value,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<DateTime?> getLastSyncedAt() async {
    final key = 'farmer_products_last_sync_$_owner';
    final row = await (_db.select(
      _db.syncMetadata,
    )..where((item) => item.key.equals(key))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value);
  }

  Future<void> refreshFromRemote() async {
    final owner = _owner;
    final remoteProducts = await _remote.listarProductosRaw();
    final now = DateTime.now();
    final remoteIds = remoteProducts
        .map((item) => item['id'].toString())
        .toSet();

    await _db.transaction(() async {
      for (final item in remoteProducts) {
        final id = item['id'].toString();
        final local = await (_db.select(
          _db.cachedFarmerProducts,
        )..where((row) => row.localId.equals(id))).getSingleOrNull();
        if (local != null && local.syncState != EntitySyncState.synced.value) {
          continue;
        }
        await _db
            .into(_db.cachedFarmerProducts)
            .insertOnConflictUpdate(
              CachedFarmerProductsCompanion.insert(
                localId: id,
                remoteId: Value(id),
                ownerUsername: owner,
                payloadJson: jsonEncode(item),
                syncState: EntitySyncState.synced.value,
                updatedAt: now,
                lastSyncedAt: Value(now),
              ),
            );
      }

      final syncedRows =
          await (_db.select(_db.cachedFarmerProducts)..where(
                (row) =>
                    row.ownerUsername.equals(owner) &
                    row.syncState.equals(EntitySyncState.synced.value),
              ))
              .get();
      for (final row in syncedRows) {
        if (!remoteIds.contains(row.remoteId ?? row.localId)) {
          await (_db.delete(
            _db.cachedFarmerProducts,
          )..where((item) => item.localId.equals(row.localId))).go();
        }
      }

      final localIds =
          (await (_db.select(
                _db.cachedFarmerProducts,
              )..where((row) => row.ownerUsername.equals(owner))).get())
              .map((row) => row.localId)
              .toSet();
      final productOperations =
          await (_db.select(_db.syncOperations)..where(
                (row) =>
                    row.ownerUsername.equals(owner) &
                    row.entityType.equals('PRODUCT') &
                    row.state.isNotValue(SyncOperationState.synced.value),
              ))
              .get();
      for (final operation in productOperations) {
        if (!localIds.contains(operation.entityLocalId)) {
          await (_db.delete(
            _db.syncOperations,
          )..where((row) => row.id.equals(operation.id))).go();
        }
      }

      await _db
          .into(_db.syncMetadata)
          .insertOnConflictUpdate(
            SyncMetadataCompanion.insert(
              key: 'farmer_products_last_sync_$owner',
              value: now.toIso8601String(),
            ),
          );
    });
  }

  Future<String> createProduct(
    Map<String, dynamic> payload, {
    required File imageFile,
  }) async {
    final owner = _owner;
    final localId = _uuid.v4();
    final operationId = _uuid.v4();
    final imagePath = await _images.preserve(imageFile, localId);
    final now = DateTime.now();
    final localPayload = <String, dynamic>{
      ...payload,
      'id': localId,
      'clientId': localId,
      'imageUrl': imagePath,
      'status': 'DISPONIBLE',
    };

    await _db.transaction(() async {
      await _db
          .into(_db.cachedFarmerProducts)
          .insert(
            CachedFarmerProductsCompanion.insert(
              localId: localId,
              ownerUsername: owner,
              payloadJson: jsonEncode(localPayload),
              imagePath: Value(imagePath),
              syncState: EntitySyncState.pending.value,
              updatedAt: now,
            ),
          );
      await _insertOperation(
        id: operationId,
        localId: localId,
        type: SyncOperationType.createProduct,
        payload: localPayload,
        imagePath: imagePath,
        now: now,
      );
    });
    unawaited(syncPending());
    return localId;
  }

  Future<void> updateProduct(
    String localId,
    Map<String, dynamic> payload, {
    File? imageFile,
  }) async {
    final cached = await (_db.select(
      _db.cachedFarmerProducts,
    )..where((row) => row.localId.equals(localId))).getSingle();
    var oldPayload = jsonDecode(cached.payloadJson) as Map<String, dynamic>;
    if (cached.syncState == EntitySyncState.conflict.value) {
      try {
        final remoteProducts = await _remote.listarProductosRaw();
        final remoteId = cached.remoteId ?? localId;
        final remoteProduct = remoteProducts
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (item) => item?['id']?.toString() == remoteId,
              orElse: () => null,
            );
        if (remoteProduct != null) {
          oldPayload = <String, dynamic>{
            ...oldPayload,
            'version': remoteProduct['version'],
          };
        }
      } catch (_) {
        // Keep the local version when offline; the operation remains retryable.
      }
    }
    var imagePath = cached.imagePath;
    if (imageFile != null) {
      imagePath = await _images.preserve(imageFile, localId);
    }
    final merged = <String, dynamic>{
      ...oldPayload,
      ...payload,
      'id': localId,
      if (imagePath != null) 'imageUrl': imagePath,
    };
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(
        _db.cachedFarmerProducts,
      )..where((row) => row.localId.equals(localId))).write(
        CachedFarmerProductsCompanion(
          payloadJson: Value(jsonEncode(merged)),
          imagePath: Value(imagePath),
          syncState: Value(EntitySyncState.pending.value),
          updatedAt: Value(now),
        ),
      );

      final createOperation = await _pendingOperation(
        localId,
        SyncOperationType.createProduct,
      );
      if (createOperation != null) {
        await _replaceOperationPayload(createOperation.id, merged, imagePath);
        return;
      }
      final updateOperation = await _pendingOperation(
        localId,
        SyncOperationType.updateProduct,
      );
      if (updateOperation != null) {
        await _replaceOperationPayload(updateOperation.id, merged, imagePath);
        return;
      }
      await _insertOperation(
        id: _uuid.v4(),
        localId: localId,
        remoteId: cached.remoteId ?? localId,
        type: SyncOperationType.updateProduct,
        payload: merged,
        imagePath: imagePath,
        now: now,
      );
    });
    unawaited(syncPending());
  }

  Future<void> deleteProduct(String localId) async {
    final cached = await (_db.select(
      _db.cachedFarmerProducts,
    )..where((row) => row.localId.equals(localId))).getSingle();
    final createOperation = await _pendingOperation(
      localId,
      SyncOperationType.createProduct,
    );
    if (createOperation != null) {
      await _db.transaction(() async {
        await (_db.delete(
          _db.syncOperations,
        )..where((row) => row.entityLocalId.equals(localId))).go();
        await (_db.delete(
          _db.cachedFarmerProducts,
        )..where((row) => row.localId.equals(localId))).go();
      });
      await _images.deleteIfManaged(cached.imagePath);
      return;
    }

    final now = DateTime.now();
    await _db.transaction(() async {
      // A deletion supersedes every queued update for the same product.
      await (_db.delete(_db.syncOperations)..where(
            (row) =>
                row.ownerUsername.equals(_owner) &
                row.entityLocalId.equals(localId) &
                row.operationType.isIn([
                  SyncOperationType.updateProduct.value,
                  SyncOperationType.deleteProduct.value,
                ]),
          ))
          .go();
      await (_db.update(
        _db.cachedFarmerProducts,
      )..where((row) => row.localId.equals(localId))).write(
        CachedFarmerProductsCompanion(
          isDeleted: const Value(true),
          syncState: Value(EntitySyncState.pending.value),
          updatedAt: Value(now),
        ),
      );
      await _insertOperation(
        id: _uuid.v4(),
        localId: localId,
        remoteId: cached.remoteId ?? localId,
        type: SyncOperationType.deleteProduct,
        payload: const {},
        now: now,
      );
    });
    unawaited(syncPending());
  }

  Future<void> syncPending({
    bool includeFailed = false,
    bool force = false,
  }) async {
    if (_syncing || SessionManager().rol != 'AGRICULTOR') return;
    _syncing = true;
    try {
      final states = [SyncOperationState.pending.value];
      if (includeFailed) states.add(SyncOperationState.failed.value);
      while (true) {
        final operation =
            await (_db.select(_db.syncOperations)
                  ..where(
                    (row) =>
                        row.ownerUsername.equals(_owner) &
                        row.operationType.isIn([
                          SyncOperationType.createProduct.value,
                          SyncOperationType.updateProduct.value,
                          SyncOperationType.deleteProduct.value,
                        ]) &
                        row.state.isIn(states),
                  )
                  ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
                  ..limit(1))
                .getSingleOrNull();
        if (operation == null) break;
        if (!force && !_retryWindowReached(operation)) break;
        final succeeded = await _syncOperation(operation);
        if (!succeeded) break;
      }
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _syncOperation(SyncOperation operation) async {
    final attemptAt = DateTime.now();
    await (_db.update(
      _db.syncOperations,
    )..where((row) => row.id.equals(operation.id))).write(
      SyncOperationsCompanion(
        state: Value(SyncOperationState.syncing.value),
        lastAttemptAt: Value(attemptAt),
        attempts: Value(operation.attempts + 1),
        lastError: const Value(null),
      ),
    );

    try {
      final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      Map<String, dynamic>? response;
      switch (operation.operationType) {
        case 'CREATE_PRODUCT':
          response = await _remote.agregarProductoRaw(
            payload,
            imageFile: File(operation.imagePath!),
          );
        case 'UPDATE_PRODUCT':
          response = await _remote.modificarProductoRaw(
            operation.remoteId ?? operation.entityLocalId,
            payload,
            imageFile: operation.imagePath == null
                ? null
                : File(operation.imagePath!),
          );
        case 'DELETE_PRODUCT':
          await _remote.eliminarProducto(
            operation.remoteId ?? operation.entityLocalId,
          );
        default:
          throw StateError(
            'Operacion no soportada: ${operation.operationType}',
          );
      }

      await _db.transaction(() async {
        if (operation.operationType == 'DELETE_PRODUCT') {
          await (_db.delete(
            _db.cachedFarmerProducts,
          )..where((row) => row.localId.equals(operation.entityLocalId))).go();
        } else {
          final remoteId = response!['id'].toString();
          final newerOperation =
              await (_db.select(_db.syncOperations)
                    ..where(
                      (row) =>
                          row.ownerUsername.equals(operation.ownerUsername) &
                          row.entityLocalId.equals(operation.entityLocalId) &
                          row.id.equals(operation.id).not() &
                          row.state.isIn([
                            SyncOperationState.pending.value,
                            SyncOperationState.failed.value,
                            SyncOperationState.conflict.value,
                          ]),
                    )
                    ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
                    ..limit(1))
                  .getSingleOrNull();

          if (newerOperation == null) {
            await (_db.update(_db.cachedFarmerProducts)
                  ..where((row) => row.localId.equals(operation.entityLocalId)))
                .write(
                  CachedFarmerProductsCompanion(
                    remoteId: Value(remoteId),
                    payloadJson: Value(jsonEncode(response)),
                    imagePath: const Value(null),
                    syncState: Value(EntitySyncState.synced.value),
                    updatedAt: Value(attemptAt),
                    lastSyncedAt: Value(attemptAt),
                  ),
                );
          } else {
            final nextPayload =
                jsonDecode(newerOperation.payloadJson) as Map<String, dynamic>;
            nextPayload['version'] = response['version'];
            await (_db.update(
              _db.syncOperations,
            )..where((row) => row.id.equals(newerOperation.id))).write(
              SyncOperationsCompanion(
                remoteId: Value(remoteId),
                payloadJson: Value(jsonEncode(nextPayload)),
                state: Value(SyncOperationState.pending.value),
                lastError: const Value(null),
              ),
            );
            await (_db.update(_db.cachedFarmerProducts)
                  ..where((row) => row.localId.equals(operation.entityLocalId)))
                .write(
                  CachedFarmerProductsCompanion(
                    remoteId: Value(remoteId),
                    payloadJson: Value(jsonEncode(nextPayload)),
                    syncState: Value(EntitySyncState.pending.value),
                    updatedAt: Value(attemptAt),
                    lastSyncedAt: Value(attemptAt),
                  ),
                );
          }
        }
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(operation.id))).write(
          SyncOperationsCompanion(
            state: Value(SyncOperationState.synced.value),
            lastError: const Value(null),
          ),
        );
      });
      final imageStillQueued =
          await (_db.select(_db.syncOperations)..where(
                (row) =>
                    row.entityLocalId.equals(operation.entityLocalId) &
                    row.imagePath.equalsNullable(operation.imagePath) &
                    row.state.isIn([
                      SyncOperationState.pending.value,
                      SyncOperationState.failed.value,
                      SyncOperationState.conflict.value,
                    ]),
              ))
              .getSingleOrNull();
      if (imageStillQueued == null) {
        await _images.deleteIfManaged(operation.imagePath);
      }
      return true;
    } catch (error) {
      final message = error.toString();
      final conflict = message.contains('409') || message.contains('404');
      final state = conflict
          ? SyncOperationState.conflict
          : SyncOperationState.failed;
      await _db.transaction(() async {
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(operation.id))).write(
          SyncOperationsCompanion(
            state: Value(state.value),
            lastError: Value(message),
          ),
        );
        await (_db.update(
          _db.cachedFarmerProducts,
        )..where((row) => row.localId.equals(operation.entityLocalId))).write(
          CachedFarmerProductsCompanion(
            syncState: Value(
              conflict
                  ? EntitySyncState.conflict.value
                  : EntitySyncState.failed.value,
            ),
          ),
        );
      });
      _scheduleRetry(operation.attempts + 1);
      return false;
    }
  }

  bool _retryWindowReached(SyncOperation operation) {
    final lastAttempt = operation.lastAttemptAt;
    if (lastAttempt == null || operation.attempts == 0) return true;
    return !DateTime.now().isBefore(
      lastAttempt.add(_retryDelay(operation.attempts)),
    );
  }

  Duration _retryDelay(int attempts) {
    final exponent = attempts.clamp(1, 8);
    return Duration(seconds: 1 << exponent);
  }

  void _scheduleRetry(int attempts) {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay(attempts), () {
      unawaited(syncPending(includeFailed: true));
    });
  }

  OfflineFarmerProduct _mapCachedProduct(CachedFarmerProduct row) {
    return OfflineFarmerProduct(
      product: Producto.fromJson(
        jsonDecode(row.payloadJson) as Map<String, dynamic>,
      ),
      syncState: EntitySyncState.values.firstWhere(
        (value) => value.value == row.syncState,
        orElse: () => EntitySyncState.pending,
      ),
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
    );
  }

  Future<SyncOperation?> _pendingOperation(
    String localId,
    SyncOperationType type,
  ) {
    return (_db.select(_db.syncOperations)..where(
          (row) =>
              row.entityLocalId.equals(localId) &
              row.operationType.equals(type.value) &
              row.state.isIn([
                SyncOperationState.pending.value,
                SyncOperationState.failed.value,
                SyncOperationState.conflict.value,
              ]),
        ))
        .getSingleOrNull();
  }

  Future<void> _replaceOperationPayload(
    String operationId,
    Map<String, dynamic> payload,
    String? imagePath,
  ) {
    return (_db.update(
      _db.syncOperations,
    )..where((row) => row.id.equals(operationId))).write(
      SyncOperationsCompanion(
        payloadJson: Value(jsonEncode(payload)),
        imagePath: Value(imagePath),
        state: Value(SyncOperationState.pending.value),
        attempts: const Value(0),
        lastAttemptAt: const Value(null),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> _insertOperation({
    required String id,
    required String localId,
    required SyncOperationType type,
    required Map<String, dynamic> payload,
    required DateTime now,
    String? remoteId,
    String? imagePath,
  }) {
    return _db
        .into(_db.syncOperations)
        .insert(
          SyncOperationsCompanion.insert(
            id: id,
            idempotencyKey: id,
            ownerUsername: _owner,
            role: 'AGRICULTOR',
            operationType: type.value,
            entityType: 'PRODUCT',
            entityLocalId: localId,
            remoteId: Value(remoteId),
            payloadJson: jsonEncode(payload),
            imagePath: Value(imagePath),
            createdAt: now,
            state: SyncOperationState.pending.value,
          ),
        );
  }
}
