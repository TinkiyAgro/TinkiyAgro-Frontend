// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedFarmerProductsTable extends CachedFarmerProducts
    with TableInfo<$CachedFarmerProductsTable, CachedFarmerProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFarmerProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    ownerUsername,
    payloadJson,
    imagePath,
    syncState,
    isDeleted,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_farmer_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFarmerProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CachedFarmerProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFarmerProduct(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $CachedFarmerProductsTable createAlias(String alias) {
    return $CachedFarmerProductsTable(attachedDatabase, alias);
  }
}

class CachedFarmerProduct extends DataClass
    implements Insertable<CachedFarmerProduct> {
  final String localId;
  final String? remoteId;
  final String ownerUsername;
  final String payloadJson;
  final String? imagePath;
  final String syncState;
  final bool isDeleted;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedFarmerProduct({
    required this.localId,
    this.remoteId,
    required this.ownerUsername,
    required this.payloadJson,
    this.imagePath,
    required this.syncState,
    required this.isDeleted,
    required this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['owner_username'] = Variable<String>(ownerUsername);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedFarmerProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedFarmerProductsCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      ownerUsername: Value(ownerUsername),
      payloadJson: Value(payloadJson),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      syncState: Value(syncState),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedFarmerProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFarmerProduct(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      syncState: serializer.fromJson<String>(json['syncState']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'imagePath': serializer.toJson<String?>(imagePath),
      'syncState': serializer.toJson<String>(syncState),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedFarmerProduct copyWith({
    String? localId,
    Value<String?> remoteId = const Value.absent(),
    String? ownerUsername,
    String? payloadJson,
    Value<String?> imagePath = const Value.absent(),
    String? syncState,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => CachedFarmerProduct(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    ownerUsername: ownerUsername ?? this.ownerUsername,
    payloadJson: payloadJson ?? this.payloadJson,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    syncState: syncState ?? this.syncState,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  CachedFarmerProduct copyWithCompanion(CachedFarmerProductsCompanion data) {
    return CachedFarmerProduct(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFarmerProduct(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('syncState: $syncState, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    ownerUsername,
    payloadJson,
    imagePath,
    syncState,
    isDeleted,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFarmerProduct &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.ownerUsername == this.ownerUsername &&
          other.payloadJson == this.payloadJson &&
          other.imagePath == this.imagePath &&
          other.syncState == this.syncState &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedFarmerProductsCompanion
    extends UpdateCompanion<CachedFarmerProduct> {
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String> ownerUsername;
  final Value<String> payloadJson;
  final Value<String?> imagePath;
  final Value<String> syncState;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedFarmerProductsCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.syncState = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFarmerProductsCompanion.insert({
    required String localId,
    this.remoteId = const Value.absent(),
    required String ownerUsername,
    required String payloadJson,
    this.imagePath = const Value.absent(),
    required String syncState,
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       ownerUsername = Value(ownerUsername),
       payloadJson = Value(payloadJson),
       syncState = Value(syncState),
       updatedAt = Value(updatedAt);
  static Insertable<CachedFarmerProduct> custom({
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? ownerUsername,
    Expression<String>? payloadJson,
    Expression<String>? imagePath,
    Expression<String>? syncState,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (imagePath != null) 'image_path': imagePath,
      if (syncState != null) 'sync_state': syncState,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFarmerProductsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? remoteId,
    Value<String>? ownerUsername,
    Value<String>? payloadJson,
    Value<String?>? imagePath,
    Value<String>? syncState,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedFarmerProductsCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      payloadJson: payloadJson ?? this.payloadJson,
      imagePath: imagePath ?? this.imagePath,
      syncState: syncState ?? this.syncState,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFarmerProductsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('syncState: $syncState, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPickupPointsTable extends CachedPickupPoints
    with TableInfo<$CachedPickupPointsTable, CachedPickupPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPickupPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    ownerUsername,
    payloadJson,
    syncState,
    isDeleted,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pickup_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPickupPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CachedPickupPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPickupPoint(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $CachedPickupPointsTable createAlias(String alias) {
    return $CachedPickupPointsTable(attachedDatabase, alias);
  }
}

class CachedPickupPoint extends DataClass
    implements Insertable<CachedPickupPoint> {
  final String localId;
  final String? remoteId;
  final String ownerUsername;
  final String payloadJson;
  final String syncState;
  final bool isDeleted;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedPickupPoint({
    required this.localId,
    this.remoteId,
    required this.ownerUsername,
    required this.payloadJson,
    required this.syncState,
    required this.isDeleted,
    required this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['owner_username'] = Variable<String>(ownerUsername);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_state'] = Variable<String>(syncState);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedPickupPointsCompanion toCompanion(bool nullToAbsent) {
    return CachedPickupPointsCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      ownerUsername: Value(ownerUsername),
      payloadJson: Value(payloadJson),
      syncState: Value(syncState),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedPickupPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPickupPoint(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncState: serializer.fromJson<String>(json['syncState']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncState': serializer.toJson<String>(syncState),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedPickupPoint copyWith({
    String? localId,
    Value<String?> remoteId = const Value.absent(),
    String? ownerUsername,
    String? payloadJson,
    String? syncState,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => CachedPickupPoint(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    ownerUsername: ownerUsername ?? this.ownerUsername,
    payloadJson: payloadJson ?? this.payloadJson,
    syncState: syncState ?? this.syncState,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  CachedPickupPoint copyWithCompanion(CachedPickupPointsCompanion data) {
    return CachedPickupPoint(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPickupPoint(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncState: $syncState, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    ownerUsername,
    payloadJson,
    syncState,
    isDeleted,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPickupPoint &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.ownerUsername == this.ownerUsername &&
          other.payloadJson == this.payloadJson &&
          other.syncState == this.syncState &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedPickupPointsCompanion extends UpdateCompanion<CachedPickupPoint> {
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String> ownerUsername;
  final Value<String> payloadJson;
  final Value<String> syncState;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedPickupPointsCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncState = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPickupPointsCompanion.insert({
    required String localId,
    this.remoteId = const Value.absent(),
    required String ownerUsername,
    required String payloadJson,
    required String syncState,
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       ownerUsername = Value(ownerUsername),
       payloadJson = Value(payloadJson),
       syncState = Value(syncState),
       updatedAt = Value(updatedAt);
  static Insertable<CachedPickupPoint> custom({
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? ownerUsername,
    Expression<String>? payloadJson,
    Expression<String>? syncState,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncState != null) 'sync_state': syncState,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPickupPointsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? remoteId,
    Value<String>? ownerUsername,
    Value<String>? payloadJson,
    Value<String>? syncState,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedPickupPointsCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      payloadJson: payloadJson ?? this.payloadJson,
      syncState: syncState ?? this.syncState,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPickupPointsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncState: $syncState, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFarmerOrderGroupsTable extends CachedFarmerOrderGroups
    with TableInfo<$CachedFarmerOrderGroupsTable, CachedFarmerOrderGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFarmerOrderGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupKey,
    ownerUsername,
    payloadJson,
    syncState,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_farmer_order_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFarmerOrderGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupKey};
  @override
  CachedFarmerOrderGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFarmerOrderGroup(
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $CachedFarmerOrderGroupsTable createAlias(String alias) {
    return $CachedFarmerOrderGroupsTable(attachedDatabase, alias);
  }
}

class CachedFarmerOrderGroup extends DataClass
    implements Insertable<CachedFarmerOrderGroup> {
  final String groupKey;
  final String ownerUsername;
  final String payloadJson;
  final String syncState;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedFarmerOrderGroup({
    required this.groupKey,
    required this.ownerUsername,
    required this.payloadJson,
    required this.syncState,
    required this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_key'] = Variable<String>(groupKey);
    map['owner_username'] = Variable<String>(ownerUsername);
    map['payload_json'] = Variable<String>(payloadJson);
    map['sync_state'] = Variable<String>(syncState);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedFarmerOrderGroupsCompanion toCompanion(bool nullToAbsent) {
    return CachedFarmerOrderGroupsCompanion(
      groupKey: Value(groupKey),
      ownerUsername: Value(ownerUsername),
      payloadJson: Value(payloadJson),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedFarmerOrderGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFarmerOrderGroup(
      groupKey: serializer.fromJson<String>(json['groupKey']),
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      syncState: serializer.fromJson<String>(json['syncState']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupKey': serializer.toJson<String>(groupKey),
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'syncState': serializer.toJson<String>(syncState),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedFarmerOrderGroup copyWith({
    String? groupKey,
    String? ownerUsername,
    String? payloadJson,
    String? syncState,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => CachedFarmerOrderGroup(
    groupKey: groupKey ?? this.groupKey,
    ownerUsername: ownerUsername ?? this.ownerUsername,
    payloadJson: payloadJson ?? this.payloadJson,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  CachedFarmerOrderGroup copyWithCompanion(
    CachedFarmerOrderGroupsCompanion data,
  ) {
    return CachedFarmerOrderGroup(
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFarmerOrderGroup(')
          ..write('groupKey: $groupKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupKey,
    ownerUsername,
    payloadJson,
    syncState,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFarmerOrderGroup &&
          other.groupKey == this.groupKey &&
          other.ownerUsername == this.ownerUsername &&
          other.payloadJson == this.payloadJson &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedFarmerOrderGroupsCompanion
    extends UpdateCompanion<CachedFarmerOrderGroup> {
  final Value<String> groupKey;
  final Value<String> ownerUsername;
  final Value<String> payloadJson;
  final Value<String> syncState;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedFarmerOrderGroupsCompanion({
    this.groupKey = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFarmerOrderGroupsCompanion.insert({
    required String groupKey,
    required String ownerUsername,
    required String payloadJson,
    required String syncState,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupKey = Value(groupKey),
       ownerUsername = Value(ownerUsername),
       payloadJson = Value(payloadJson),
       syncState = Value(syncState),
       updatedAt = Value(updatedAt);
  static Insertable<CachedFarmerOrderGroup> custom({
    Expression<String>? groupKey,
    Expression<String>? ownerUsername,
    Expression<String>? payloadJson,
    Expression<String>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupKey != null) 'group_key': groupKey,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFarmerOrderGroupsCompanion copyWith({
    Value<String>? groupKey,
    Value<String>? ownerUsername,
    Value<String>? payloadJson,
    Value<String>? syncState,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedFarmerOrderGroupsCompanion(
      groupKey: groupKey ?? this.groupKey,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      payloadJson: payloadJson ?? this.payloadJson,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFarmerOrderGroupsCompanion(')
          ..write('groupKey: $groupKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCourierDeliveryGroupsTable extends CachedCourierDeliveryGroups
    with
        TableInfo<
          $CachedCourierDeliveryGroupsTable,
          CachedCourierDeliveryGroup
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCourierDeliveryGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupKey,
    ownerUsername,
    payloadJson,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_courier_delivery_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCourierDeliveryGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerUsername, groupKey};
  @override
  CachedCourierDeliveryGroup map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCourierDeliveryGroup(
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $CachedCourierDeliveryGroupsTable createAlias(String alias) {
    return $CachedCourierDeliveryGroupsTable(attachedDatabase, alias);
  }
}

class CachedCourierDeliveryGroup extends DataClass
    implements Insertable<CachedCourierDeliveryGroup> {
  final String groupKey;
  final String ownerUsername;
  final String payloadJson;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const CachedCourierDeliveryGroup({
    required this.groupKey,
    required this.ownerUsername,
    required this.payloadJson,
    required this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_key'] = Variable<String>(groupKey);
    map['owner_username'] = Variable<String>(ownerUsername);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  CachedCourierDeliveryGroupsCompanion toCompanion(bool nullToAbsent) {
    return CachedCourierDeliveryGroupsCompanion(
      groupKey: Value(groupKey),
      ownerUsername: Value(ownerUsername),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory CachedCourierDeliveryGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCourierDeliveryGroup(
      groupKey: serializer.fromJson<String>(json['groupKey']),
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupKey': serializer.toJson<String>(groupKey),
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  CachedCourierDeliveryGroup copyWith({
    String? groupKey,
    String? ownerUsername,
    String? payloadJson,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => CachedCourierDeliveryGroup(
    groupKey: groupKey ?? this.groupKey,
    ownerUsername: ownerUsername ?? this.ownerUsername,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  CachedCourierDeliveryGroup copyWithCompanion(
    CachedCourierDeliveryGroupsCompanion data,
  ) {
    return CachedCourierDeliveryGroup(
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCourierDeliveryGroup(')
          ..write('groupKey: $groupKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupKey,
    ownerUsername,
    payloadJson,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCourierDeliveryGroup &&
          other.groupKey == this.groupKey &&
          other.ownerUsername == this.ownerUsername &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CachedCourierDeliveryGroupsCompanion
    extends UpdateCompanion<CachedCourierDeliveryGroup> {
  final Value<String> groupKey;
  final Value<String> ownerUsername;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const CachedCourierDeliveryGroupsCompanion({
    this.groupKey = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCourierDeliveryGroupsCompanion.insert({
    required String groupKey,
    required String ownerUsername,
    required String payloadJson,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupKey = Value(groupKey),
       ownerUsername = Value(ownerUsername),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedCourierDeliveryGroup> custom({
    Expression<String>? groupKey,
    Expression<String>? ownerUsername,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupKey != null) 'group_key': groupKey,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCourierDeliveryGroupsCompanion copyWith({
    Value<String>? groupKey,
    Value<String>? ownerUsername,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedCourierDeliveryGroupsCompanion(
      groupKey: groupKey ?? this.groupKey,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCourierDeliveryGroupsCompanion(')
          ..write('groupKey: $groupKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourierTrackingUpdatesTable extends CourierTrackingUpdates
    with TableInfo<$CourierTrackingUpdatesTable, CourierTrackingUpdate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourierTrackingUpdatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subOrderIdMeta = const VerificationMeta(
    'subOrderId',
  );
  @override
  late final GeneratedColumn<String> subOrderId = GeneratedColumn<String>(
    'sub_order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerUsername,
    subOrderId,
    label,
    latitude,
    longitude,
    capturedAt,
    syncedAt,
    syncState,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courier_tracking_updates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourierTrackingUpdate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('sub_order_id')) {
      context.handle(
        _subOrderIdMeta,
        subOrderId.isAcceptableOrUnknown(
          data['sub_order_id']!,
          _subOrderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subOrderIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerUsername, subOrderId};
  @override
  CourierTrackingUpdate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourierTrackingUpdate(
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      subOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_order_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $CourierTrackingUpdatesTable createAlias(String alias) {
    return $CourierTrackingUpdatesTable(attachedDatabase, alias);
  }
}

class CourierTrackingUpdate extends DataClass
    implements Insertable<CourierTrackingUpdate> {
  final String ownerUsername;
  final String subOrderId;
  final String label;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final DateTime? syncedAt;
  final String syncState;
  final String? lastError;
  const CourierTrackingUpdate({
    required this.ownerUsername,
    required this.subOrderId,
    required this.label,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    this.syncedAt,
    required this.syncState,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_username'] = Variable<String>(ownerUsername);
    map['sub_order_id'] = Variable<String>(subOrderId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  CourierTrackingUpdatesCompanion toCompanion(bool nullToAbsent) {
    return CourierTrackingUpdatesCompanion(
      ownerUsername: Value(ownerUsername),
      subOrderId: Value(subOrderId),
      label: Value(label),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      capturedAt: Value(capturedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      syncState: Value(syncState),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory CourierTrackingUpdate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourierTrackingUpdate(
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      subOrderId: serializer.fromJson<String>(json['subOrderId']),
      label: serializer.fromJson<String>(json['label']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'subOrderId': serializer.toJson<String>(subOrderId),
      'label': serializer.toJson<String>(label),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'syncState': serializer.toJson<String>(syncState),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  CourierTrackingUpdate copyWith({
    String? ownerUsername,
    String? subOrderId,
    String? label,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? capturedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    String? syncState,
    Value<String?> lastError = const Value.absent(),
  }) => CourierTrackingUpdate(
    ownerUsername: ownerUsername ?? this.ownerUsername,
    subOrderId: subOrderId ?? this.subOrderId,
    label: label ?? this.label,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    capturedAt: capturedAt ?? this.capturedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    syncState: syncState ?? this.syncState,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  CourierTrackingUpdate copyWithCompanion(
    CourierTrackingUpdatesCompanion data,
  ) {
    return CourierTrackingUpdate(
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      subOrderId: data.subOrderId.present
          ? data.subOrderId.value
          : this.subOrderId,
      label: data.label.present ? data.label.value : this.label,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourierTrackingUpdate(')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('subOrderId: $subOrderId, ')
          ..write('label: $label, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncState: $syncState, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerUsername,
    subOrderId,
    label,
    latitude,
    longitude,
    capturedAt,
    syncedAt,
    syncState,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourierTrackingUpdate &&
          other.ownerUsername == this.ownerUsername &&
          other.subOrderId == this.subOrderId &&
          other.label == this.label &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.capturedAt == this.capturedAt &&
          other.syncedAt == this.syncedAt &&
          other.syncState == this.syncState &&
          other.lastError == this.lastError);
}

class CourierTrackingUpdatesCompanion
    extends UpdateCompanion<CourierTrackingUpdate> {
  final Value<String> ownerUsername;
  final Value<String> subOrderId;
  final Value<String> label;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> capturedAt;
  final Value<DateTime?> syncedAt;
  final Value<String> syncState;
  final Value<String?> lastError;
  final Value<int> rowid;
  const CourierTrackingUpdatesCompanion({
    this.ownerUsername = const Value.absent(),
    this.subOrderId = const Value.absent(),
    this.label = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourierTrackingUpdatesCompanion.insert({
    required String ownerUsername,
    required String subOrderId,
    required String label,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime capturedAt,
    this.syncedAt = const Value.absent(),
    required String syncState,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerUsername = Value(ownerUsername),
       subOrderId = Value(subOrderId),
       label = Value(label),
       capturedAt = Value(capturedAt),
       syncState = Value(syncState);
  static Insertable<CourierTrackingUpdate> custom({
    Expression<String>? ownerUsername,
    Expression<String>? subOrderId,
    Expression<String>? label,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? syncState,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (subOrderId != null) 'sub_order_id': subOrderId,
      if (label != null) 'label': label,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (syncState != null) 'sync_state': syncState,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourierTrackingUpdatesCompanion copyWith({
    Value<String>? ownerUsername,
    Value<String>? subOrderId,
    Value<String>? label,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? capturedAt,
    Value<DateTime?>? syncedAt,
    Value<String>? syncState,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return CourierTrackingUpdatesCompanion(
      ownerUsername: ownerUsername ?? this.ownerUsername,
      subOrderId: subOrderId ?? this.subOrderId,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      syncState: syncState ?? this.syncState,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (subOrderId.present) {
      map['sub_order_id'] = Variable<String>(subOrderId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourierTrackingUpdatesCompanion(')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('subOrderId: $subOrderId, ')
          ..write('label: $label, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncState: $syncState, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTable extends SyncOperations
    with TableInfo<$SyncOperationsTable, SyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ownerUsernameMeta = const VerificationMeta(
    'ownerUsername',
  );
  @override
  late final GeneratedColumn<String> ownerUsername = GeneratedColumn<String>(
    'owner_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityLocalIdMeta = const VerificationMeta(
    'entityLocalId',
  );
  @override
  late final GeneratedColumn<String> entityLocalId = GeneratedColumn<String>(
    'entity_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    ownerUsername,
    role,
    operationType,
    entityType,
    entityLocalId,
    remoteId,
    payloadJson,
    imagePath,
    createdAt,
    lastAttemptAt,
    attempts,
    state,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('owner_username')) {
      context.handle(
        _ownerUsernameMeta,
        ownerUsername.isAcceptableOrUnknown(
          data['owner_username']!,
          _ownerUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUsernameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
        _entityLocalIdMeta,
        entityLocalId.isAcceptableOrUnknown(
          data['entity_local_id']!,
          _entityLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityLocalIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      ownerUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_username'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOperationsTable createAlias(String alias) {
    return $SyncOperationsTable(attachedDatabase, alias);
  }
}

class SyncOperation extends DataClass implements Insertable<SyncOperation> {
  final String id;
  final String idempotencyKey;
  final String ownerUsername;
  final String role;
  final String operationType;
  final String entityType;
  final String entityLocalId;
  final String? remoteId;
  final String payloadJson;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attempts;
  final String state;
  final String? lastError;
  const SyncOperation({
    required this.id,
    required this.idempotencyKey,
    required this.ownerUsername,
    required this.role,
    required this.operationType,
    required this.entityType,
    required this.entityLocalId,
    this.remoteId,
    required this.payloadJson,
    this.imagePath,
    required this.createdAt,
    this.lastAttemptAt,
    required this.attempts,
    required this.state,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['owner_username'] = Variable<String>(ownerUsername);
    map['role'] = Variable<String>(role);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_local_id'] = Variable<String>(entityLocalId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['attempts'] = Variable<int>(attempts);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      ownerUsername: Value(ownerUsername),
      role: Value(role),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityLocalId: Value(entityLocalId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      payloadJson: Value(payloadJson),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      attempts: Value(attempts),
      state: Value(state),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperation(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      ownerUsername: serializer.fromJson<String>(json['ownerUsername']),
      role: serializer.fromJson<String>(json['role']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityLocalId: serializer.fromJson<String>(json['entityLocalId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      state: serializer.fromJson<String>(json['state']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'ownerUsername': serializer.toJson<String>(ownerUsername),
      'role': serializer.toJson<String>(role),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityLocalId': serializer.toJson<String>(entityLocalId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'attempts': serializer.toJson<int>(attempts),
      'state': serializer.toJson<String>(state),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOperation copyWith({
    String? id,
    String? idempotencyKey,
    String? ownerUsername,
    String? role,
    String? operationType,
    String? entityType,
    String? entityLocalId,
    Value<String?> remoteId = const Value.absent(),
    String? payloadJson,
    Value<String?> imagePath = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    int? attempts,
    String? state,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOperation(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    ownerUsername: ownerUsername ?? this.ownerUsername,
    role: role ?? this.role,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityLocalId: entityLocalId ?? this.entityLocalId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    payloadJson: payloadJson ?? this.payloadJson,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    attempts: attempts ?? this.attempts,
    state: state ?? this.state,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOperation copyWithCompanion(SyncOperationsCompanion data) {
    return SyncOperation(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      ownerUsername: data.ownerUsername.present
          ? data.ownerUsername.value
          : this.ownerUsername,
      role: data.role.present ? data.role.value : this.role,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityLocalId: data.entityLocalId.present
          ? data.entityLocalId.value
          : this.entityLocalId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      state: data.state.present ? data.state.value : this.state,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperation(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('role: $role, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    ownerUsername,
    role,
    operationType,
    entityType,
    entityLocalId,
    remoteId,
    payloadJson,
    imagePath,
    createdAt,
    lastAttemptAt,
    attempts,
    state,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperation &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.ownerUsername == this.ownerUsername &&
          other.role == this.role &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.remoteId == this.remoteId &&
          other.payloadJson == this.payloadJson &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.attempts == this.attempts &&
          other.state == this.state &&
          other.lastError == this.lastError);
}

class SyncOperationsCompanion extends UpdateCompanion<SyncOperation> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> ownerUsername;
  final Value<String> role;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityLocalId;
  final Value<String?> remoteId;
  final Value<String> payloadJson;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> attempts;
  final Value<String> state;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOperationsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.ownerUsername = const Value.absent(),
    this.role = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.state = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String ownerUsername,
    required String role,
    required String operationType,
    required String entityType,
    required String entityLocalId,
    this.remoteId = const Value.absent(),
    required String payloadJson,
    this.imagePath = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.attempts = const Value.absent(),
    required String state,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       ownerUsername = Value(ownerUsername),
       role = Value(role),
       operationType = Value(operationType),
       entityType = Value(entityType),
       entityLocalId = Value(entityLocalId),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       state = Value(state);
  static Insertable<SyncOperation> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? ownerUsername,
    Expression<String>? role,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityLocalId,
    Expression<String>? remoteId,
    Expression<String>? payloadJson,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? attempts,
    Expression<String>? state,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (ownerUsername != null) 'owner_username': ownerUsername,
      if (role != null) 'role': role,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (remoteId != null) 'remote_id': remoteId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (attempts != null) 'attempts': attempts,
      if (state != null) 'state': state,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? ownerUsername,
    Value<String>? role,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityLocalId,
    Value<String?>? remoteId,
    Value<String>? payloadJson,
    Value<String?>? imagePath,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? attempts,
    Value<String>? state,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOperationsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      role: role ?? this.role,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      remoteId: remoteId ?? this.remoteId,
      payloadJson: payloadJson ?? this.payloadJson,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attempts: attempts ?? this.attempts,
      state: state ?? this.state,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (ownerUsername.present) {
      map['owner_username'] = Variable<String>(ownerUsername.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<String>(entityLocalId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('ownerUsername: $ownerUsername, ')
          ..write('role: $role, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('state: $state, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final String key;
  final String value;
  const SyncMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetadataData copyWith({String? key, String? value}) =>
      SyncMetadataData(key: key ?? this.key, value: value ?? this.value);
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedFarmerProductsTable cachedFarmerProducts =
      $CachedFarmerProductsTable(this);
  late final $CachedPickupPointsTable cachedPickupPoints =
      $CachedPickupPointsTable(this);
  late final $CachedFarmerOrderGroupsTable cachedFarmerOrderGroups =
      $CachedFarmerOrderGroupsTable(this);
  late final $CachedCourierDeliveryGroupsTable cachedCourierDeliveryGroups =
      $CachedCourierDeliveryGroupsTable(this);
  late final $CourierTrackingUpdatesTable courierTrackingUpdates =
      $CourierTrackingUpdatesTable(this);
  late final $SyncOperationsTable syncOperations = $SyncOperationsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedFarmerProducts,
    cachedPickupPoints,
    cachedFarmerOrderGroups,
    cachedCourierDeliveryGroups,
    courierTrackingUpdates,
    syncOperations,
    syncMetadata,
  ];
}

typedef $$CachedFarmerProductsTableCreateCompanionBuilder =
    CachedFarmerProductsCompanion Function({
      required String localId,
      Value<String?> remoteId,
      required String ownerUsername,
      required String payloadJson,
      Value<String?> imagePath,
      required String syncState,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedFarmerProductsTableUpdateCompanionBuilder =
    CachedFarmerProductsCompanion Function({
      Value<String> localId,
      Value<String?> remoteId,
      Value<String> ownerUsername,
      Value<String> payloadJson,
      Value<String?> imagePath,
      Value<String> syncState,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$CachedFarmerProductsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFarmerProductsTable> {
  $$CachedFarmerProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFarmerProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFarmerProductsTable> {
  $$CachedFarmerProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFarmerProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFarmerProductsTable> {
  $$CachedFarmerProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedFarmerProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFarmerProductsTable,
          CachedFarmerProduct,
          $$CachedFarmerProductsTableFilterComposer,
          $$CachedFarmerProductsTableOrderingComposer,
          $$CachedFarmerProductsTableAnnotationComposer,
          $$CachedFarmerProductsTableCreateCompanionBuilder,
          $$CachedFarmerProductsTableUpdateCompanionBuilder,
          (
            CachedFarmerProduct,
            BaseReferences<
              _$AppDatabase,
              $CachedFarmerProductsTable,
              CachedFarmerProduct
            >,
          ),
          CachedFarmerProduct,
          PrefetchHooks Function()
        > {
  $$CachedFarmerProductsTableTableManager(
    _$AppDatabase db,
    $CachedFarmerProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFarmerProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFarmerProductsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedFarmerProductsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> ownerUsername = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFarmerProductsCompanion(
                localId: localId,
                remoteId: remoteId,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                imagePath: imagePath,
                syncState: syncState,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> remoteId = const Value.absent(),
                required String ownerUsername,
                required String payloadJson,
                Value<String?> imagePath = const Value.absent(),
                required String syncState,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFarmerProductsCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                imagePath: imagePath,
                syncState: syncState,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFarmerProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFarmerProductsTable,
      CachedFarmerProduct,
      $$CachedFarmerProductsTableFilterComposer,
      $$CachedFarmerProductsTableOrderingComposer,
      $$CachedFarmerProductsTableAnnotationComposer,
      $$CachedFarmerProductsTableCreateCompanionBuilder,
      $$CachedFarmerProductsTableUpdateCompanionBuilder,
      (
        CachedFarmerProduct,
        BaseReferences<
          _$AppDatabase,
          $CachedFarmerProductsTable,
          CachedFarmerProduct
        >,
      ),
      CachedFarmerProduct,
      PrefetchHooks Function()
    >;
typedef $$CachedPickupPointsTableCreateCompanionBuilder =
    CachedPickupPointsCompanion Function({
      required String localId,
      Value<String?> remoteId,
      required String ownerUsername,
      required String payloadJson,
      required String syncState,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedPickupPointsTableUpdateCompanionBuilder =
    CachedPickupPointsCompanion Function({
      Value<String> localId,
      Value<String?> remoteId,
      Value<String> ownerUsername,
      Value<String> payloadJson,
      Value<String> syncState,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$CachedPickupPointsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPickupPointsTable> {
  $$CachedPickupPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPickupPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPickupPointsTable> {
  $$CachedPickupPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPickupPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPickupPointsTable> {
  $$CachedPickupPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedPickupPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPickupPointsTable,
          CachedPickupPoint,
          $$CachedPickupPointsTableFilterComposer,
          $$CachedPickupPointsTableOrderingComposer,
          $$CachedPickupPointsTableAnnotationComposer,
          $$CachedPickupPointsTableCreateCompanionBuilder,
          $$CachedPickupPointsTableUpdateCompanionBuilder,
          (
            CachedPickupPoint,
            BaseReferences<
              _$AppDatabase,
              $CachedPickupPointsTable,
              CachedPickupPoint
            >,
          ),
          CachedPickupPoint,
          PrefetchHooks Function()
        > {
  $$CachedPickupPointsTableTableManager(
    _$AppDatabase db,
    $CachedPickupPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPickupPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPickupPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPickupPointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> ownerUsername = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPickupPointsCompanion(
                localId: localId,
                remoteId: remoteId,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                syncState: syncState,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> remoteId = const Value.absent(),
                required String ownerUsername,
                required String payloadJson,
                required String syncState,
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPickupPointsCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                syncState: syncState,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPickupPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPickupPointsTable,
      CachedPickupPoint,
      $$CachedPickupPointsTableFilterComposer,
      $$CachedPickupPointsTableOrderingComposer,
      $$CachedPickupPointsTableAnnotationComposer,
      $$CachedPickupPointsTableCreateCompanionBuilder,
      $$CachedPickupPointsTableUpdateCompanionBuilder,
      (
        CachedPickupPoint,
        BaseReferences<
          _$AppDatabase,
          $CachedPickupPointsTable,
          CachedPickupPoint
        >,
      ),
      CachedPickupPoint,
      PrefetchHooks Function()
    >;
typedef $$CachedFarmerOrderGroupsTableCreateCompanionBuilder =
    CachedFarmerOrderGroupsCompanion Function({
      required String groupKey,
      required String ownerUsername,
      required String payloadJson,
      required String syncState,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedFarmerOrderGroupsTableUpdateCompanionBuilder =
    CachedFarmerOrderGroupsCompanion Function({
      Value<String> groupKey,
      Value<String> ownerUsername,
      Value<String> payloadJson,
      Value<String> syncState,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$CachedFarmerOrderGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFarmerOrderGroupsTable> {
  $$CachedFarmerOrderGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFarmerOrderGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFarmerOrderGroupsTable> {
  $$CachedFarmerOrderGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFarmerOrderGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFarmerOrderGroupsTable> {
  $$CachedFarmerOrderGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedFarmerOrderGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFarmerOrderGroupsTable,
          CachedFarmerOrderGroup,
          $$CachedFarmerOrderGroupsTableFilterComposer,
          $$CachedFarmerOrderGroupsTableOrderingComposer,
          $$CachedFarmerOrderGroupsTableAnnotationComposer,
          $$CachedFarmerOrderGroupsTableCreateCompanionBuilder,
          $$CachedFarmerOrderGroupsTableUpdateCompanionBuilder,
          (
            CachedFarmerOrderGroup,
            BaseReferences<
              _$AppDatabase,
              $CachedFarmerOrderGroupsTable,
              CachedFarmerOrderGroup
            >,
          ),
          CachedFarmerOrderGroup,
          PrefetchHooks Function()
        > {
  $$CachedFarmerOrderGroupsTableTableManager(
    _$AppDatabase db,
    $CachedFarmerOrderGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFarmerOrderGroupsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedFarmerOrderGroupsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedFarmerOrderGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> groupKey = const Value.absent(),
                Value<String> ownerUsername = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFarmerOrderGroupsCompanion(
                groupKey: groupKey,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                syncState: syncState,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupKey,
                required String ownerUsername,
                required String payloadJson,
                required String syncState,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFarmerOrderGroupsCompanion.insert(
                groupKey: groupKey,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                syncState: syncState,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFarmerOrderGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFarmerOrderGroupsTable,
      CachedFarmerOrderGroup,
      $$CachedFarmerOrderGroupsTableFilterComposer,
      $$CachedFarmerOrderGroupsTableOrderingComposer,
      $$CachedFarmerOrderGroupsTableAnnotationComposer,
      $$CachedFarmerOrderGroupsTableCreateCompanionBuilder,
      $$CachedFarmerOrderGroupsTableUpdateCompanionBuilder,
      (
        CachedFarmerOrderGroup,
        BaseReferences<
          _$AppDatabase,
          $CachedFarmerOrderGroupsTable,
          CachedFarmerOrderGroup
        >,
      ),
      CachedFarmerOrderGroup,
      PrefetchHooks Function()
    >;
typedef $$CachedCourierDeliveryGroupsTableCreateCompanionBuilder =
    CachedCourierDeliveryGroupsCompanion Function({
      required String groupKey,
      required String ownerUsername,
      required String payloadJson,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedCourierDeliveryGroupsTableUpdateCompanionBuilder =
    CachedCourierDeliveryGroupsCompanion Function({
      Value<String> groupKey,
      Value<String> ownerUsername,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$CachedCourierDeliveryGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCourierDeliveryGroupsTable> {
  $$CachedCourierDeliveryGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCourierDeliveryGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCourierDeliveryGroupsTable> {
  $$CachedCourierDeliveryGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCourierDeliveryGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCourierDeliveryGroupsTable> {
  $$CachedCourierDeliveryGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedCourierDeliveryGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCourierDeliveryGroupsTable,
          CachedCourierDeliveryGroup,
          $$CachedCourierDeliveryGroupsTableFilterComposer,
          $$CachedCourierDeliveryGroupsTableOrderingComposer,
          $$CachedCourierDeliveryGroupsTableAnnotationComposer,
          $$CachedCourierDeliveryGroupsTableCreateCompanionBuilder,
          $$CachedCourierDeliveryGroupsTableUpdateCompanionBuilder,
          (
            CachedCourierDeliveryGroup,
            BaseReferences<
              _$AppDatabase,
              $CachedCourierDeliveryGroupsTable,
              CachedCourierDeliveryGroup
            >,
          ),
          CachedCourierDeliveryGroup,
          PrefetchHooks Function()
        > {
  $$CachedCourierDeliveryGroupsTableTableManager(
    _$AppDatabase db,
    $CachedCourierDeliveryGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCourierDeliveryGroupsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedCourierDeliveryGroupsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCourierDeliveryGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> groupKey = const Value.absent(),
                Value<String> ownerUsername = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCourierDeliveryGroupsCompanion(
                groupKey: groupKey,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupKey,
                required String ownerUsername,
                required String payloadJson,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCourierDeliveryGroupsCompanion.insert(
                groupKey: groupKey,
                ownerUsername: ownerUsername,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCourierDeliveryGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCourierDeliveryGroupsTable,
      CachedCourierDeliveryGroup,
      $$CachedCourierDeliveryGroupsTableFilterComposer,
      $$CachedCourierDeliveryGroupsTableOrderingComposer,
      $$CachedCourierDeliveryGroupsTableAnnotationComposer,
      $$CachedCourierDeliveryGroupsTableCreateCompanionBuilder,
      $$CachedCourierDeliveryGroupsTableUpdateCompanionBuilder,
      (
        CachedCourierDeliveryGroup,
        BaseReferences<
          _$AppDatabase,
          $CachedCourierDeliveryGroupsTable,
          CachedCourierDeliveryGroup
        >,
      ),
      CachedCourierDeliveryGroup,
      PrefetchHooks Function()
    >;
typedef $$CourierTrackingUpdatesTableCreateCompanionBuilder =
    CourierTrackingUpdatesCompanion Function({
      required String ownerUsername,
      required String subOrderId,
      required String label,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime capturedAt,
      Value<DateTime?> syncedAt,
      required String syncState,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$CourierTrackingUpdatesTableUpdateCompanionBuilder =
    CourierTrackingUpdatesCompanion Function({
      Value<String> ownerUsername,
      Value<String> subOrderId,
      Value<String> label,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> capturedAt,
      Value<DateTime?> syncedAt,
      Value<String> syncState,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$CourierTrackingUpdatesTableFilterComposer
    extends Composer<_$AppDatabase, $CourierTrackingUpdatesTable> {
  $$CourierTrackingUpdatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subOrderId => $composableBuilder(
    column: $table.subOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CourierTrackingUpdatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourierTrackingUpdatesTable> {
  $$CourierTrackingUpdatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subOrderId => $composableBuilder(
    column: $table.subOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CourierTrackingUpdatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourierTrackingUpdatesTable> {
  $$CourierTrackingUpdatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subOrderId => $composableBuilder(
    column: $table.subOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$CourierTrackingUpdatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourierTrackingUpdatesTable,
          CourierTrackingUpdate,
          $$CourierTrackingUpdatesTableFilterComposer,
          $$CourierTrackingUpdatesTableOrderingComposer,
          $$CourierTrackingUpdatesTableAnnotationComposer,
          $$CourierTrackingUpdatesTableCreateCompanionBuilder,
          $$CourierTrackingUpdatesTableUpdateCompanionBuilder,
          (
            CourierTrackingUpdate,
            BaseReferences<
              _$AppDatabase,
              $CourierTrackingUpdatesTable,
              CourierTrackingUpdate
            >,
          ),
          CourierTrackingUpdate,
          PrefetchHooks Function()
        > {
  $$CourierTrackingUpdatesTableTableManager(
    _$AppDatabase db,
    $CourierTrackingUpdatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourierTrackingUpdatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CourierTrackingUpdatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourierTrackingUpdatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerUsername = const Value.absent(),
                Value<String> subOrderId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourierTrackingUpdatesCompanion(
                ownerUsername: ownerUsername,
                subOrderId: subOrderId,
                label: label,
                latitude: latitude,
                longitude: longitude,
                capturedAt: capturedAt,
                syncedAt: syncedAt,
                syncState: syncState,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerUsername,
                required String subOrderId,
                required String label,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime capturedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                required String syncState,
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourierTrackingUpdatesCompanion.insert(
                ownerUsername: ownerUsername,
                subOrderId: subOrderId,
                label: label,
                latitude: latitude,
                longitude: longitude,
                capturedAt: capturedAt,
                syncedAt: syncedAt,
                syncState: syncState,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CourierTrackingUpdatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourierTrackingUpdatesTable,
      CourierTrackingUpdate,
      $$CourierTrackingUpdatesTableFilterComposer,
      $$CourierTrackingUpdatesTableOrderingComposer,
      $$CourierTrackingUpdatesTableAnnotationComposer,
      $$CourierTrackingUpdatesTableCreateCompanionBuilder,
      $$CourierTrackingUpdatesTableUpdateCompanionBuilder,
      (
        CourierTrackingUpdate,
        BaseReferences<
          _$AppDatabase,
          $CourierTrackingUpdatesTable,
          CourierTrackingUpdate
        >,
      ),
      CourierTrackingUpdate,
      PrefetchHooks Function()
    >;
typedef $$SyncOperationsTableCreateCompanionBuilder =
    SyncOperationsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String ownerUsername,
      required String role,
      required String operationType,
      required String entityType,
      required String entityLocalId,
      Value<String?> remoteId,
      required String payloadJson,
      Value<String?> imagePath,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attempts,
      required String state,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncOperationsTableUpdateCompanionBuilder =
    SyncOperationsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> ownerUsername,
      Value<String> role,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityLocalId,
      Value<String?> remoteId,
      Value<String> payloadJson,
      Value<String?> imagePath,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attempts,
      Value<String> state,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUsername => $composableBuilder(
    column: $table.ownerUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOperationsTable,
          SyncOperation,
          $$SyncOperationsTableFilterComposer,
          $$SyncOperationsTableOrderingComposer,
          $$SyncOperationsTableAnnotationComposer,
          $$SyncOperationsTableCreateCompanionBuilder,
          $$SyncOperationsTableUpdateCompanionBuilder,
          (
            SyncOperation,
            BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
          ),
          SyncOperation,
          PrefetchHooks Function()
        > {
  $$SyncOperationsTableTableManager(
    _$AppDatabase db,
    $SyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> ownerUsername = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityLocalId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                ownerUsername: ownerUsername,
                role: role,
                operationType: operationType,
                entityType: entityType,
                entityLocalId: entityLocalId,
                remoteId: remoteId,
                payloadJson: payloadJson,
                imagePath: imagePath,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attempts: attempts,
                state: state,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String ownerUsername,
                required String role,
                required String operationType,
                required String entityType,
                required String entityLocalId,
                Value<String?> remoteId = const Value.absent(),
                required String payloadJson,
                Value<String?> imagePath = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required String state,
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                ownerUsername: ownerUsername,
                role: role,
                operationType: operationType,
                entityType: entityType,
                entityLocalId: entityLocalId,
                remoteId: remoteId,
                payloadJson: payloadJson,
                imagePath: imagePath,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attempts: attempts,
                state: state,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOperationsTable,
      SyncOperation,
      $$SyncOperationsTableFilterComposer,
      $$SyncOperationsTableOrderingComposer,
      $$SyncOperationsTableAnnotationComposer,
      $$SyncOperationsTableCreateCompanionBuilder,
      $$SyncOperationsTableUpdateCompanionBuilder,
      (
        SyncOperation,
        BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
      ),
      SyncOperation,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataData,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataData,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
          ),
          SyncMetadataData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataData,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataData,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataData>,
      ),
      SyncMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedFarmerProductsTableTableManager get cachedFarmerProducts =>
      $$CachedFarmerProductsTableTableManager(_db, _db.cachedFarmerProducts);
  $$CachedPickupPointsTableTableManager get cachedPickupPoints =>
      $$CachedPickupPointsTableTableManager(_db, _db.cachedPickupPoints);
  $$CachedFarmerOrderGroupsTableTableManager get cachedFarmerOrderGroups =>
      $$CachedFarmerOrderGroupsTableTableManager(
        _db,
        _db.cachedFarmerOrderGroups,
      );
  $$CachedCourierDeliveryGroupsTableTableManager
  get cachedCourierDeliveryGroups =>
      $$CachedCourierDeliveryGroupsTableTableManager(
        _db,
        _db.cachedCourierDeliveryGroups,
      );
  $$CourierTrackingUpdatesTableTableManager get courierTrackingUpdates =>
      $$CourierTrackingUpdatesTableTableManager(
        _db,
        _db.courierTrackingUpdates,
      );
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(_db, _db.syncOperations);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
