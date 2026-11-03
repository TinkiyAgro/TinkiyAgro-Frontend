import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/app_database.dart';
import '../../../core/offline/sync_types.dart';
import '../../../core/evaluation/gps_evaluation.dart';
import '../../../core/session_manager.dart';
import 'remote/courier_service.dart';

class CourierTrackingStatus {
  const CourierTrackingStatus({
    required this.subOrderId,
    required this.label,
    required this.capturedAt,
    required this.syncState,
    this.syncedAt,
    this.lastError,
  });

  final String subOrderId;
  final String label;
  final DateTime capturedAt;
  final DateTime? syncedAt;
  final EntitySyncState syncState;
  final String? lastError;
}

class CourierTrackingRepository {
  CourierTrackingRepository._()
    : _db = AppDatabase.instance,
      _remote = CourierService(),
      _uuid = const Uuid();

  CourierTrackingRepository.forTesting({
    required AppDatabase database,
    required CourierRemoteDataSource remote,
    Uuid uuid = const Uuid(),
  }) : _db = database,
       _remote = remote,
       _uuid = uuid;

  static final CourierTrackingRepository instance =
      CourierTrackingRepository._();

  final AppDatabase _db;
  final CourierRemoteDataSource _remote;
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
      throw StateError('No hay un repartidor autenticado para el tracking.');
    }
    return username;
  }

  Stream<List<CourierTrackingStatus>> watchStatuses(List<String> subOrderIds) {
    if (subOrderIds.isEmpty) {
      return Stream.value(const []);
    }
    final query = _db.select(_db.courierTrackingUpdates)
      ..where(
        (row) =>
            row.ownerUsername.equals(_owner) & row.subOrderId.isIn(subOrderIds),
      );
    return query.watch().map(
      (rows) => rows.map(_mapStatus).toList(growable: false),
    );
  }

  Future<void> recordLocation({
    required String subOrderId,
    required String label,
    required double latitude,
    required double longitude,
    double? accuracyM,
    DateTime? capturedAt,
  }) async {
    final owner = _owner;
    final captured = capturedAt ?? DateTime.now();
    final payload = <String, dynamic>{
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyM != null) 'accuracyM': accuracyM,
      'capturedAt': captured.toUtc().toIso8601String(),
    };
    final existing =
        await (_db.select(_db.syncOperations)
              ..where(
                (row) =>
                    row.ownerUsername.equals(owner) &
                    row.operationType.equals(
                      SyncOperationType.updateTracking.value,
                    ) &
                    row.entityLocalId.equals(subOrderId),
              )
              ..limit(1))
            .getSingleOrNull();

    await _db.transaction(() async {
      await _db
          .into(_db.courierTrackingUpdates)
          .insertOnConflictUpdate(
            CourierTrackingUpdatesCompanion.insert(
              ownerUsername: owner,
              subOrderId: subOrderId,
              label: label,
              latitude: Value(latitude),
              longitude: Value(longitude),
              capturedAt: captured,
              syncState: EntitySyncState.pending.value,
            ),
          );
      if (existing == null) {
        final operationId = _uuid.v4();
        await _db
            .into(_db.syncOperations)
            .insert(
              SyncOperationsCompanion.insert(
                id: operationId,
                idempotencyKey: operationId,
                ownerUsername: owner,
                role: 'REPARTIDOR',
                operationType: SyncOperationType.updateTracking.value,
                entityType: 'COURIER_DELIVERY',
                entityLocalId: subOrderId,
                remoteId: Value(subOrderId),
                payloadJson: jsonEncode(payload),
                createdAt: captured,
                state: SyncOperationState.pending.value,
              ),
            );
      } else {
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(existing.id))).write(
          SyncOperationsCompanion(
            payloadJson: Value(jsonEncode(payload)),
            createdAt: Value(captured),
            lastAttemptAt: const Value(null),
            attempts: const Value(0),
            state: Value(SyncOperationState.pending.value),
            lastError: const Value(null),
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
    if (_syncing || SessionManager().rol != 'REPARTIDOR') return;
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
                        SyncOperationType.updateTracking.value,
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
    final sentPayload =
        jsonDecode(operation.payloadJson) as Map<String, dynamic>;
    final sentCapturedAt = sentPayload['capturedAt']?.toString();
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
      final response = await _remote
          .updateTrackingRaw(operation.entityLocalId, {
            'label': sentPayload['label'],
            'latitude': sentPayload['latitude'],
            'longitude': sentPayload['longitude'],
            'capturedAt': sentPayload['capturedAt'],
          });
      final measurementId = GpsEvaluation.trackingMeasurementId(response);
      final accuracy = (sentPayload['accuracyM'] as num?)?.toDouble();
      if (GpsEvaluation.enabled && measurementId != null && accuracy != null) {
        try {
          await GpsEvaluation.recordContinuous(
            trackingMeasurementId: measurementId,
            latitude: (sentPayload['latitude'] as num).toDouble(),
            longitude: (sentPayload['longitude'] as num).toDouble(),
            accuracyM: accuracy,
            capturedAt: DateTime.parse(sentPayload['capturedAt'] as String),
          );
        } catch (error) {
          debugPrint('[GpsEvaluation] no se pudo registrar la muestra: $error');
        }
      }
      await _db.transaction(() async {
        final currentOperation = await (_db.select(
          _db.syncOperations,
        )..where((row) => row.id.equals(operation.id))).getSingle();
        final currentPayload =
            jsonDecode(currentOperation.payloadJson) as Map<String, dynamic>;
        final hasNewerCapture =
            currentPayload['capturedAt']?.toString() != sentCapturedAt;
        if (hasNewerCapture) {
          await (_db.update(
            _db.syncOperations,
          )..where((row) => row.id.equals(operation.id))).write(
            SyncOperationsCompanion(
              state: Value(SyncOperationState.pending.value),
            ),
          );
          return;
        }
        await (_db.update(
          _db.syncOperations,
        )..where((row) => row.id.equals(operation.id))).write(
          SyncOperationsCompanion(
            state: Value(SyncOperationState.synced.value),
          ),
        );
        await (_db.update(_db.courierTrackingUpdates)..where(
              (row) =>
                  row.ownerUsername.equals(operation.ownerUsername) &
                  row.subOrderId.equals(operation.entityLocalId),
            ))
            .write(
              CourierTrackingUpdatesCompanion(
                syncedAt: Value(attemptAt),
                syncState: Value(EntitySyncState.synced.value),
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
        await (_db.update(_db.courierTrackingUpdates)..where(
              (row) =>
                  row.ownerUsername.equals(operation.ownerUsername) &
                  row.subOrderId.equals(operation.entityLocalId),
            ))
            .write(
              CourierTrackingUpdatesCompanion(
                syncState: Value(
                  conflict
                      ? EntitySyncState.conflict.value
                      : EntitySyncState.failed.value,
                ),
                lastError: Value(message),
              ),
            );
      });
      if (!conflict) _scheduleRetry(operation.attempts + 1);
      return false;
    }
  }

  Future<void> clearCurrentUserData() async {
    final owner = _owner;
    await _db.transaction(() async {
      await (_db.delete(
        _db.courierTrackingUpdates,
      )..where((row) => row.ownerUsername.equals(owner))).go();
      await (_db.delete(_db.syncOperations)..where(
            (row) =>
                row.ownerUsername.equals(owner) &
                row.operationType.equals(
                  SyncOperationType.updateTracking.value,
                ),
          ))
          .go();
    });
  }

  CourierTrackingStatus _mapStatus(CourierTrackingUpdate row) {
    return CourierTrackingStatus(
      subOrderId: row.subOrderId,
      label: row.label,
      capturedAt: row.capturedAt,
      syncedAt: row.syncedAt,
      syncState: EntitySyncState.values.firstWhere(
        (state) => state.value == row.syncState,
        orElse: () => EntitySyncState.pending,
      ),
      lastError: row.lastError,
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
