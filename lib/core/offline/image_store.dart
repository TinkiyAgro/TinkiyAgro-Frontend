import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class LocalImageStore {
  Future<String> preserve(File source, String localId);
  Future<void> deleteIfManaged(String? path);
}

class OfflineImageStore implements LocalImageStore {
  const OfflineImageStore();

  @override
  Future<String> preserve(File source, String localId) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'pending_product_images'));
    await directory.create(recursive: true);
    final extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path).toLowerCase();
    final target = File(p.join(directory.path, '$localId$extension'));
    if (p.equals(source.path, target.path)) return target.path;
    await source.copy(target.path);
    return target.path;
  }

  @override
  Future<void> deleteIfManaged(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists() && path.contains('pending_product_images')) {
      await file.delete();
    }
  }
}
