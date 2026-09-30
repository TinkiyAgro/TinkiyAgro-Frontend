import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

class OfflineMetricsExporter {
  const OfflineMetricsExporter();

  Future<File> exportCsv() async {
    final rows = await AppDatabase.instance
        .select(AppDatabase.instance.syncOperations)
        .get();
    final buffer = StringBuffer(
      'operation_id,role,type,entity,created_at,enqueued_at,last_attempt_at,synced_at,failed_at,attempts,state,network_condition,conflict_resolution,last_error\n',
    );
    for (final row in rows) {
      buffer.writeln(
        [
          row.id,
          row.role,
          row.operationType,
          row.entityType,
          row.createdAt.toIso8601String(),
          row.enqueuedAt?.toIso8601String(),
          row.lastAttemptAt?.toIso8601String(),
          row.syncedAt?.toIso8601String(),
          row.failedAt?.toIso8601String(),
          row.attempts,
          row.state,
          row.networkCondition,
          row.conflictResolution,
          row.lastError,
        ].map(_csv).join(','),
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, 'offline-sync-metrics.csv'))
      ..writeAsStringSync(buffer.toString());
  }

  String _csv(Object? value) =>
      value == null ? '' : '"${value.toString().replaceAll('"', '""')}"';
}
