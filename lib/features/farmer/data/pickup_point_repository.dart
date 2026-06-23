import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/app_database.dart';
import '../../../core/offline/sync_types.dart';
import '../../../core/session_manager.dart';
import 'offline_pickup_point.dart';
import 'pickup_point_model.dart';
import 'remote/pickup_point_service.dart';

class PickupPointRepository {
  PickupPointRepository._()
    : _db = AppDatabase.instance,
      _remote = PickupPointService(),
      _uuid = const Uuid();

  PickupPointRepository.forTesting({
    required AppDatabase database,
    required PickupPointRemoteDataSource remote,
    Uuid uuid = const Uuid(),
  }) : _db = database,
       _remote = remote,
       _uuid = uuid;

  static final PickupPointRepository instance = PickupPointRepository._();

  final AppDatabase _db;
  final PickupPointRemoteDataSource _remote;
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

  Stream<List<OfflinePickupPoint>> watchPickupPoints() {
    final owner = _owner;
    final query = _db.select(_db.cachedPickupPoints)
      ..where((row) => row.ownerUsername.equals(owner) & row.isDeleted.not())
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
      (rows) => rows.map(_mapCached).toList(growable: false),
    );
  }

  Stream<int> watchPendingCount() {
    final owner = _owner;
    final count = _db.syncOperations.id.count();
    final query = _db.selectOnly(_db.syncOperations)
      ..addColumns([count])
      ..where(
        _db.syncOperations.ownerUsername.equals(owner) &
            _db.syncOperations.operationType.isIn([
              SyncOperationType.createPickupPoint.value,
              SyncOperationType.updatePickupPoint.value,
              SyncOperationType.deletePickupPoint.value,
            ]) &
            _db.syncOperations.state.isIn([
              SyncOperationState.pending.value,
              SyncOperationState.failed.value,
              SyncOperationState.conflict.value,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<DateTime?> getLastSyncedAt() async {
    final row = await (_db.select(
      _db.syncMetadata,
    )..where((item) => item.key.equals(_lastSyncKey))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value);
  }

  Stream<DateTime?> watchLastSyncedAt() {
    final query = _db.select(_db.syncMetadata)
      ..where((item) => item.key.equals(_lastSyncKey));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : DateTime.tryParse(row.value),
    );
  }

  String get _lastSyncKey => 'pickup_points_last_sync_$_owner';

  Future<void> refreshFromRemote() async {
    final owner = _owner;
    final remotePoints = await _remote.listarRaw();
    final now = DateTime.now();
    final remoteIds = remotePoints.map((item) => item['id'].toString()).toSet();

    await _db.transaction(() async {
      for (final item in remotePoints) {
        final id = item['id'].toString();
        final cached = await (_db.select(
          _db.cachedPickupPoints,
        )..where((row) => row.localId.equals(id))).getSingleOrNull();
        if (cached != null &&
            cached.syncState != EntitySyncState.synced.value) {
          continue;
        }
        await _db
            .into(_db.cachedPickupPoints)
            .insertOnConflictUpdate(
              CachedPickupPointsCompanion.insert(
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

      final synced =
          await (_db.select(_db.cachedPickupPoints)..where(
                (row) =>
                    row.ownerUsername.equals(owner) &
                    row.syncState.equals(EntitySyncState.synced.value),
              ))
              .get();
      for (final point in synced) {
        if (!remoteIds.contains(point.remoteId ?? point.localId)) {
          await (_db.delete(
            _db.cachedPickupPoints,
          )..where((row) => row.localId.equals(point.localId))).go();
        }
      }

      await _db
          .into(_db.syncMetadata)
          .insertOnConflictUpdate(
            SyncMetadataCompanion.insert(
              key: _lastSyncKey,
              value: now.toIso8601String(),
            ),
          );
    });
  }

  Future<String> createPickupPoint(Map<String, dynamic> payload) async {
    final localId = _uuid.v4();
    final now = DateTime.now();
    final localPayload = <String, dynamic>{
      ...payload,
      'id': localId,
      'clientId': localId,
      'farmerUsername': _owner,
    };

    await _db.transaction(() async {
      await _db
          .into(_db.cachedPickupPoints)
          .insert(
            CachedPickupPointsCompanion.insert(
              localId: localId,
              ownerUsername: _owner,
              payloadJson: jsonEncode(localPayload),
              syncState: EntitySyncState.pending.value,
              updatedAt: now,
            ),
          );
      await _insertOperation(
        id: _uuid.v4(),
        localId: localId,
        type: SyncOperationType.createPickupPoint,
        payload: localPayload,
        now: now,
      );
    });
    unawaited(syncPending());
    return localId;
  }

  Future<void> updatePickupPoint(
    String localId,
    Map<String, dynamic> payload,
  ) async {
    final cached = await (_db.select(
      _db.cachedPickupPoints,
    )..where((row) => row.localId.equals(localId))).getSingle();
    final previous = jsonDecode(cached.payloadJson) as Map<String, dynamic>;
    final merged = <String, dynamic>{...previous, ...payload, 'id': localId};
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(
        _db.cachedPickupPoints,
      )..where((row) => row.localId.equals(localId))).write(
        CachedPickupPointsCompanion(
          payloadJson: Value(jsonEncode(merged)),
          syncState: Value(EntitySyncState.pending.value),
          updatedAt: Value(now),
        ),
      );
      final create = await _pendingOperation(
        localId,
        SyncOperationType.createPickupPoint,
      );
      if (create != null) {
        await _replacePayload(create.id, merged);
        return;
      }
      final update = await _pendingOperation(
        localId,
        SyncOperationType.updatePickupPoint,
      );
      if (update != null) {
        await _replacePayload(update.id, merged);
        return;
      }
      await _insertOperation(
        id: _uuid.v4(),
        localId: localId,
        remoteId: cached.remoteId ?? localId,
        type: SyncOperationType.updatePickupPoint,
        payload: merged,
        now: now,
      );
    });
    unawaited(syncPending());
  }

  Future<void> deletePickupPoint(String localId) async {
    final cached = await (_db.select(
      _db.cachedPickupPoints,
    )..where((row) => row.localId.equals(localId))).getSingle();
    final create = await _pendingOperation(
      localId,
      SyncOperationType.createPickupPoint,
    );
    if (create != null) {
      await _db.transaction(() async {
        await (_db.delete(
          _db.syncOperations,
        )..where((row) => row.entityLocalId.equals(localId))).go();
        await (_db.delete(
          _db.cachedPickupPoints,
        )..where((row) => row.localId.equals(localId))).go();
      });
      return;
    }

    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(
        _db.cachedPickupPoints,
      )..where((row) => row.localId.equals(localId))).write(
        CachedPickupPointsCompanion(
          isDeleted: const Value(true),
          syncState: Value(EntitySyncState.pending.value),
          updatedAt: Value(now),
        ),
      );
      await _insertOperation(
        id: _uuid.v4(),
        localId: localId,
        remoteId: cached.remoteId ?? localId,
        type: SyncOperationType.deletePickupPoint,
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
      final operations =
          await (_db.select(_db.syncOperations)
                ..where(
                  (row) =>
                      row.ownerUsername.equals(_owner) &
                      row.operationType.isIn([
                        SyncOperationType.createPickupPoint.value,
                        SyncOperationType.updatePickupPoint.value,
                        SyncOperationType.deletePickupPoint.value,
                      ]) &
                      row.state.isIn(states),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
              .get();
      for (final operation in operations) {
        if (!force && !_retryWindowReached(operation)) continue;
        if (!await _syncOperation(operation)) break;
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
        case 'CREATE_PICKUP_POINT':
          response = await _remote.crearRaw(payload);
        case 'UPDATE_PICKUP_POINT':
          response = await _remote.editarRaw(
            operation.remoteId ?? operation.entityLocalId,
            payload,
          );
        case 'DELETE_PICKUP_POINT':
          await _remote.eliminar(operation.remoteId ?? operation.entityLocalId);
        default:
          throw StateError(
            'Operacion no soportada: ${operation.operationType}',
          );
      }

      await _db.transaction(() async {
        if (operation.operationType == 'DELETE_PICKUP_POINT') {
          await (_db.delete(
            _db.cachedPickupPoints,
          )..where((row) => row.localId.equals(operation.entityLocalId))).go();
        } else {
          final remoteId = response!['id'].toString();
          await (_db.update(
            _db.cachedPickupPoints,
          )..where((row) => row.localId.equals(operation.entityLocalId))).write(
            CachedPickupPointsCompanion(
              remoteId: Value(remoteId),
              payloadJson: Value(jsonEncode(response)),
              syncState: Value(EntitySyncState.synced.value),
              updatedAt: Value(attemptAt),
              lastSyncedAt: Value(attemptAt),
            ),
          );
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
      return true;
    } catch (error) {
      final message = error.toString();
      final conflict =
          message.contains('400') ||
          message.contains('404') ||
          message.contains('409');
      await _db.transaction(() async {
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(operation.id))).write(
          SyncOperationsCompanion(
            state: Value(
              conflict
                  ? SyncOperationState.conflict.value
                  : SyncOperationState.failed.value,
            ),
            lastError: Value(message),
          ),
        );
        await (_db.update(
          _db.cachedPickupPoints,
        )..where((row) => row.localId.equals(operation.entityLocalId))).write(
          CachedPickupPointsCompanion(
            syncState: Value(
              conflict
                  ? EntitySyncState.conflict.value
                  : EntitySyncState.failed.value,
            ),
          ),
        );
      });
      if (!conflict) _scheduleRetry(operation.attempts + 1);
      return false;
    }
  }

  OfflinePickupPoint _mapCached(CachedPickupPoint row) => OfflinePickupPoint(
    pickupPoint: PuntoRecojo.fromJson(
      jsonDecode(row.payloadJson) as Map<String, dynamic>,
    ),
    syncState: EntitySyncState.values.firstWhere(
      (state) => state.value == row.syncState,
      orElse: () => EntitySyncState.pending,
    ),
    updatedAt: row.updatedAt,
    lastSyncedAt: row.lastSyncedAt,
  );

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
              ]),
        ))
        .getSingleOrNull();
  }

  Future<void> _replacePayload(
    String operationId,
    Map<String, dynamic> payload,
  ) {
    return (_db.update(
      _db.syncOperations,
    )..where((row) => row.id.equals(operationId))).write(
      SyncOperationsCompanion(
        payloadJson: Value(jsonEncode(payload)),
        state: Value(SyncOperationState.pending.value),
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
            entityType: 'PICKUP_POINT',
            entityLocalId: localId,
            remoteId: Value(remoteId),
            payloadJson: jsonEncode(payload),
            createdAt: now,
            state: SyncOperationState.pending.value,
          ),
        );
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
}
