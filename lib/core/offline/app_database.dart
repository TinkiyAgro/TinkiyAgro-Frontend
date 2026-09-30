import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_key_store.dart';
import '../evaluation/pilot_session.dart';

part 'app_database.g.dart';

class CachedFarmerProducts extends Table {
  TextColumn get localId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get ownerUsername => text()();
  TextColumn get payloadJson => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get syncState => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class SyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get ownerUsername => text()();
  TextColumn get role => text()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get enqueuedAt =>
      dateTime().nullable().clientDefault(DateTime.now)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get failedAt => dateTime().nullable()();
  TextColumn get networkCondition =>
      text().nullable().clientDefault(() => PilotSession.networkCondition)();
  TextColumn get conflictResolution => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get state => text()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedPickupPoints extends Table {
  TextColumn get localId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get ownerUsername => text()();
  TextColumn get payloadJson => text()();
  TextColumn get syncState => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class CachedFarmerOrderGroups extends Table {
  TextColumn get groupKey => text()();
  TextColumn get ownerUsername => text()();
  TextColumn get payloadJson => text()();
  TextColumn get syncState => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {groupKey};
}

class CachedCourierDeliveryGroups extends Table {
  TextColumn get groupKey => text()();
  TextColumn get ownerUsername => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerUsername, groupKey};
}

class CourierTrackingUpdates extends Table {
  TextColumn get ownerUsername => text()();
  TextColumn get subOrderId => text()();
  TextColumn get label => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get syncState => text()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerUsername, subOrderId};
}

class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class PendingEvaluationEvents extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get productId => text()();
  TextColumn get farmerUsername => text()();
  TextColumn get sourceSection => text()();
  IntColumn get listPosition => integer()();
  TextColumn get recommendationRequestId => text().nullable()();
  TextColumn get participantId => text().nullable()();
  TextColumn get pilotSessionId => text().nullable()();
  TextColumn get networkCondition => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get enqueuedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get state => text().withDefault(const Constant('PENDING'))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedFarmerProducts,
    CachedPickupPoints,
    CachedFarmerOrderGroups,
    CachedCourierDeliveryGroups,
    CourierTrackingUpdates,
    SyncOperations,
    SyncMetadata,
    PendingEvaluationEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createSyncAuditTriggers();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(cachedPickupPoints);
      }
      if (from < 3) {
        await migrator.createTable(cachedFarmerOrderGroups);
      }
      if (from < 4) {
        await migrator.createTable(cachedCourierDeliveryGroups);
      }
      if (from < 5) {
        await migrator.createTable(courierTrackingUpdates);
      }
      if (from < 6) {
        await migrator.createTable(pendingEvaluationEvents);
      }
      if (from < 7) {
        await migrator.addColumn(syncOperations, syncOperations.enqueuedAt);
        await migrator.addColumn(syncOperations, syncOperations.syncedAt);
        await migrator.addColumn(syncOperations, syncOperations.failedAt);
        await migrator.addColumn(
          syncOperations,
          syncOperations.networkCondition,
        );
        await migrator.addColumn(
          syncOperations,
          syncOperations.conflictResolution,
        );
        await customStatement(
          "UPDATE sync_operations SET enqueued_at = created_at WHERE enqueued_at IS NULL",
        );
        await _createSyncAuditTriggers();
      }
    },
  );

  Future<void> _createSyncAuditTriggers() async {
    await customStatement(
      'DROP TRIGGER IF EXISTS sync_operations_result_audit',
    );
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS sync_operations_enqueue_audit
      AFTER INSERT ON sync_operations
      WHEN NEW.enqueued_at IS NULL
      BEGIN
        UPDATE sync_operations SET enqueued_at = NEW.created_at WHERE id = NEW.id;
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS sync_operations_result_audit
      AFTER UPDATE OF state ON sync_operations
      BEGIN
        UPDATE sync_operations SET
          synced_at = CASE WHEN NEW.state = 'synced' THEN CAST(strftime('%s', 'now') AS INTEGER) ELSE synced_at END,
          failed_at = CASE WHEN NEW.state IN ('failed', 'conflict') THEN CAST(strftime('%s', 'now') AS INTEGER) ELSE failed_at END,
          conflict_resolution = CASE WHEN NEW.state = 'conflict' THEN 'REQUIRES_REVIEW' ELSE conflict_resolution END
        WHERE id = NEW.id;
      END
    ''');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'tinkiyagro_offline.sqlite'));
    final key = await const DatabaseKeyStore().loadOrCreateHexKey();
    final isPlaintext = await _hasPlaintextSqliteHeader(file);
    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute("PRAGMA cipher = 'sqlcipher';");
        if (isPlaintext) {
          database.execute("PRAGMA hexrekey = '$key';");
        } else {
          database.execute("PRAGMA hexkey = '$key';");
        }
      },
    );
  });
}

Future<bool> _hasPlaintextSqliteHeader(File file) async {
  if (!await file.exists() || await file.length() < 16) return false;
  final bytes = await file
      .openRead(0, 16)
      .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
  return String.fromCharCodes(bytes) == 'SQLite format 3\u0000';
}
