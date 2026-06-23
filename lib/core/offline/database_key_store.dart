import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyStore {
  const DatabaseKeyStore();

  static const _storageKey = 'tinkiyagro_offline_database_key_v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(migrateWithBackup: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String> loadOrCreateHexKey() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hexKey = bytes.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join();
    await _storage.write(key: _storageKey, value: hexKey);
    return hexKey;
  }
}
