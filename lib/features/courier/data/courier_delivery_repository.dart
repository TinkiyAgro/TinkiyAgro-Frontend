import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/offline/app_database.dart';
import '../../../core/session_manager.dart';
import 'courier_model.dart';
import 'remote/courier_service.dart';

class CourierDeliveryRepository {
  CourierDeliveryRepository._()
    : _db = AppDatabase.instance,
      _remote = CourierService();

  CourierDeliveryRepository.forTesting({
    required AppDatabase database,
    required CourierRemoteDataSource remote,
  }) : _db = database,
       _remote = remote;

  static final CourierDeliveryRepository instance =
      CourierDeliveryRepository._();

  final AppDatabase _db;
  final CourierRemoteDataSource _remote;

  String get _owner {
    final session = SessionManager();
    final username =
        session.username ??
        (session.token == null
            ? null
            : SessionManager.decodeJwt(session.token!)?['sub']?.toString());
    if (username == null || username.isEmpty) {
      throw StateError('No hay un repartidor autenticado para la cache.');
    }
    return username;
  }

  String get _lastSyncKey => 'courier_deliveries_last_sync_$_owner';

  Stream<List<CourierDeliveryGroup>> watchDeliveries() {
    final owner = _owner;
    final query = _db.select(_db.cachedCourierDeliveryGroups)
      ..where((row) => row.ownerUsername.equals(owner))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CourierDeliveryGroup.fromJson(
              jsonDecode(row.payloadJson) as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<DateTime?> watchLastSyncedAt() {
    final query = _db.select(_db.syncMetadata)
      ..where((item) => item.key.equals(_lastSyncKey));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : DateTime.tryParse(row.value),
    );
  }

  Future<void> refreshFromRemote() async {
    final owner = _owner;
    final deliveries = await _remote.listDeliveriesRaw();
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedCourierDeliveryGroups,
      )..where((row) => row.ownerUsername.equals(owner))).go();
      for (final delivery in deliveries) {
        final groupKey = delivery['groupKey']?.toString() ?? '';
        if (groupKey.isEmpty) continue;
        await _db
            .into(_db.cachedCourierDeliveryGroups)
            .insert(
              CachedCourierDeliveryGroupsCompanion.insert(
                groupKey: groupKey,
                ownerUsername: owner,
                payloadJson: jsonEncode(delivery),
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
    });
  }

  Future<void> clearCurrentUserCache() async {
    final owner = _owner;
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedCourierDeliveryGroups,
      )..where((row) => row.ownerUsername.equals(owner))).go();
      await (_db.delete(_db.syncMetadata)..where(
            (row) => row.key.equals('courier_deliveries_last_sync_$owner'),
          ))
          .go();
    });
  }
}
