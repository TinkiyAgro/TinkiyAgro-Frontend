import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_key_store.dart';

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
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
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

@DriftDatabase(
  tables: [
    CachedFarmerProducts,
    CachedPickupPoints,
    CachedFarmerOrderGroups,
    CachedCourierDeliveryGroups,
    CourierTrackingUpdates,
    SyncOperations,
    SyncMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
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
    },
  );
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
