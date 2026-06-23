import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/app_database.dart';
import '../../../core/offline/sync_types.dart';
import '../../../core/session_manager.dart';
import 'farmer_order_model.dart';
import 'offline_farmer_order_group.dart';
import 'remote/farmer_order_service.dart';

class FarmerOrderRepository {
  FarmerOrderRepository._()
    : _db = AppDatabase.instance,
      _remote = FarmerOrderService(),
      _uuid = const Uuid();

  FarmerOrderRepository.forTesting({
    required AppDatabase database,
    required FarmerOrderRemoteDataSource remote,
    Uuid uuid = const Uuid(),
  }) : _db = database,
       _remote = remote,
       _uuid = uuid;

  static final FarmerOrderRepository instance = FarmerOrderRepository._();

  final AppDatabase _db;
  final FarmerOrderRemoteDataSource _remote;
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

  String get _lastSyncKey => 'farmer_orders_last_sync_$_owner';

  Stream<List<OfflineFarmerOrderGroup>> watchGroups() {
    final owner = _owner;
    final query = _db.select(_db.cachedFarmerOrderGroups)
      ..where((row) => row.ownerUsername.equals(owner))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
      (rows) => rows.map(_mapCached).toList(growable: false),
    );
  }

  Stream<int> watchPendingCount() {
    final count = _db.syncOperations.id.count();
    final query = _db.selectOnly(_db.syncOperations)
      ..addColumns([count])
      ..where(
        _db.syncOperations.ownerUsername.equals(_owner) &
            _db.syncOperations.operationType.equals(
              SyncOperationType.markOrderPrepared.value,
            ) &
            _db.syncOperations.state.isIn([
              SyncOperationState.pending.value,
              SyncOperationState.failed.value,
              SyncOperationState.conflict.value,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Stream<DateTime?> watchLastSyncedAt() {
    final query = _db.select(_db.syncMetadata)
      ..where((item) => item.key.equals(_lastSyncKey));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : DateTime.tryParse(row.value),
    );
  }

  Future<void> refreshFromRemote() async {
    final remoteGroups = await _remote.listarGruposRaw();
    await _replaceSyncedSnapshot(remoteGroups);
  }

  Future<void> markPrepared(String groupKey, List<String> subOrderIds) async {
    if (subOrderIds.isEmpty) {
      throw StateError('El grupo no contiene subpedidos para preparar.');
    }
    final cached = await (_db.select(
      _db.cachedFarmerOrderGroups,
    )..where((row) => row.groupKey.equals(groupKey))).getSingle();
    final payload = jsonDecode(cached.payloadJson) as Map<String, dynamic>;
    final optimistic = _asPrepared(payload);
    final now = DateTime.now();
    final existing =
        await (_db.select(_db.syncOperations)..where(
              (row) =>
                  row.entityLocalId.equals(groupKey) &
                  row.operationType.equals(
                    SyncOperationType.markOrderPrepared.value,
                  ) &
                  row.state.isIn([
                    SyncOperationState.pending.value,
                    SyncOperationState.failed.value,
                  ]),
            ))
            .getSingleOrNull();

    await _db.transaction(() async {
      await (_db.update(
        _db.cachedFarmerOrderGroups,
      )..where((row) => row.groupKey.equals(groupKey))).write(
        CachedFarmerOrderGroupsCompanion(
          payloadJson: Value(jsonEncode(optimistic)),
          syncState: Value(EntitySyncState.pending.value),
          updatedAt: Value(now),
        ),
      );
      final operationPayload = {'subOrderIds': subOrderIds};
      if (existing != null) {
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(existing.id))).write(
          SyncOperationsCompanion(
            payloadJson: Value(jsonEncode(operationPayload)),
            state: Value(SyncOperationState.pending.value),
            lastError: const Value(null),
          ),
        );
      } else {
        final operationId = _uuid.v4();
        await _db
            .into(_db.syncOperations)
            .insert(
              SyncOperationsCompanion.insert(
                id: operationId,
                idempotencyKey: operationId,
                ownerUsername: _owner,
                role: 'AGRICULTOR',
                operationType: SyncOperationType.markOrderPrepared.value,
                entityType: 'FARMER_ORDER_GROUP',
                entityLocalId: groupKey,
                payloadJson: jsonEncode(operationPayload),
                createdAt: now,
                state: SyncOperationState.pending.value,
              ),
            );
      }
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
                      row.operationType.equals(
                        SyncOperationType.markOrderPrepared.value,
                      ) &
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
      final ids = (payload['subOrderIds'] as List<dynamic>)
          .map((id) => id.toString())
          .toList();
      final snapshot = await _remote.marcarPreparadoRaw(ids);
      await _db.transaction(() async {
        await _replaceEntireSnapshot(
          snapshot,
          preservePendingExcept: operation.entityLocalId,
        );
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
          _db.cachedFarmerOrderGroups,
        )..where((row) => row.groupKey.equals(operation.entityLocalId))).write(
          CachedFarmerOrderGroupsCompanion(
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

  Future<void> _replaceSyncedSnapshot(
    List<Map<String, dynamic>> snapshot,
  ) async {
    await _db.transaction(() => _replaceEntireSnapshot(snapshot));
  }

  Future<void> _replaceEntireSnapshot(
    List<Map<String, dynamic>> snapshot, {
    String? preservePendingExcept,
  }) async {
    final now = DateTime.now();
    final pending =
        await (_db.select(_db.cachedFarmerOrderGroups)..where(
              (row) =>
                  row.ownerUsername.equals(_owner) &
                  row.syncState.isNotValue(EntitySyncState.synced.value),
            ))
            .get();
    final preserved = pending
        .where((row) => row.groupKey != preservePendingExcept)
        .toList();
    await (_db.delete(
      _db.cachedFarmerOrderGroups,
    )..where((row) => row.ownerUsername.equals(_owner))).go();
    for (final row in preserved) {
      await _db
          .into(_db.cachedFarmerOrderGroups)
          .insert(
            CachedFarmerOrderGroupsCompanion.insert(
              groupKey: row.groupKey,
              ownerUsername: row.ownerUsername,
              payloadJson: row.payloadJson,
              syncState: row.syncState,
              updatedAt: row.updatedAt,
              lastSyncedAt: Value(row.lastSyncedAt),
            ),
          );
    }
    for (final group in snapshot) {
      final key = group['groupKey']?.toString() ?? '';
      if (key.isEmpty || preserved.any((row) => row.groupKey == key)) continue;
      await _db
          .into(_db.cachedFarmerOrderGroups)
          .insertOnConflictUpdate(
            CachedFarmerOrderGroupsCompanion.insert(
              groupKey: key,
              ownerUsername: _owner,
              payloadJson: jsonEncode(group),
              syncState: EntitySyncState.synced.value,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
          );
    }
    await _db
        .into(_db.syncMetadata)
        .insertOnConflictUpdate(
          SyncMetadataCompanion.insert(
            key: _lastSyncKey,
            value: now.toIso8601String(),
          ),
        );
  }

  Map<String, dynamic> _asPrepared(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source);
    result['status'] = 'PREPARED';
    result['itemsToPrepare'] = <dynamic>[];
    final subOrders = result['subOrders'];
    if (subOrders is List) {
      result['subOrders'] = subOrders.map((item) {
        if (item is! Map) return item;
        return {...item.cast<String, dynamic>(), 'status': 'PREPARED'};
      }).toList();
    }
    return result;
  }

  OfflineFarmerOrderGroup _mapCached(CachedFarmerOrderGroup row) {
    return OfflineFarmerOrderGroup(
      group: FarmerOrderGroup.fromJson(
        jsonDecode(row.payloadJson) as Map<String, dynamic>,
      ),
      syncState: EntitySyncState.values.firstWhere(
        (state) => state.value == row.syncState,
        orElse: () => EntitySyncState.pending,
      ),
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
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
