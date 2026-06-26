import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/image_store.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_product_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/pickup_point_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/farmer_product_service.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/pickup_point_service.dart';

const _owner = 'farmer_emulator_experiment';
const _repetitions = int.fromEnvironment(
  'OFFLINE_EMULATOR_REPETITIONS',
  defaultValue: 5,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline-first emulator validation generates CSV', (tester) async {
    final db = AppDatabase.instance;
    await _cleanExperimentRows(db);

    final results = <EmulatorResult>[];
    for (final condition in EmulatorCondition.values) {
      for (var attempt = 1; attempt <= _repetitions; attempt++) {
        results.add(await _runProductOnEmulator(db, condition, attempt));
        results.add(await _runPickupPointOnEmulator(db, condition, attempt));
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final rawCsv = File('${dir.path}/offline_first_part_b_emulator_raw.csv');
    final summaryMd = File('${dir.path}/offline_first_part_b_emulator_summary.md');
    await rawCsv.writeAsString(_rawCsv(results));
    final summary = _summarize(results);
    final markdown = _summaryMarkdown(summary, results.length);
    await summaryMd.writeAsString(markdown);
    // ignore: avoid_print
    print('OFFLINE_FIRST_PART_B_RAW_CSV_START\n${_rawCsv(results)}OFFLINE_FIRST_PART_B_RAW_CSV_END');
    // ignore: avoid_print
    print('OFFLINE_FIRST_PART_B_SUMMARY_START\n${markdown}OFFLINE_FIRST_PART_B_SUMMARY_END');

    expect(results.where((item) => item.localSaved).length, results.length);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<EmulatorResult> _runProductOnEmulator(
  AppDatabase db,
  EmulatorCondition condition,
  int attempt,
) async {
  final temp = await getTemporaryDirectory();
  final remote = EmulatorProductRemote();
  final repository = FarmerProductRepository.forTesting(
    database: db,
    remote: remote,
    images: EmulatorImageStore(temp),
  );
  _setSession(syncEnabled: false);
  final image = File('${temp.path}/emulator-product-$condition-$attempt.jpg');
  await image.writeAsBytes([1, 2, 3, attempt]);
  await repository.createProduct(_productPayload('Producto emulador $attempt'), imageFile: image);
  final localSaved = await _hasLocalOperation(db, SyncOperationType.createProduct.value);
  final latency = await _syncCondition(
    condition,
    remote,
    () => repository.syncPending(includeFailed: true, force: true),
  );
  await _settle(condition);
  final operation = await _latestOperation(db, SyncOperationType.createProduct.value);
  return EmulatorResult(
    condition: condition,
    flow: 'crear_producto_emulador',
    attempt: attempt,
    localSaved: localSaved,
    synced: operation?.state == SyncOperationState.synced.value,
    latencyMs: latency.inMilliseconds,
    attempts: operation?.attempts ?? 0,
    finalState: operation?.state ?? 'missing',
  );
}

Future<EmulatorResult> _runPickupPointOnEmulator(
  AppDatabase db,
  EmulatorCondition condition,
  int attempt,
) async {
  final remote = EmulatorPickupPointRemote();
  final repository = PickupPointRepository.forTesting(database: db, remote: remote);
  _setSession(syncEnabled: false);
  await repository.createPickupPoint(_pointPayload('Punto emulador $attempt'));
  final localSaved = await _hasLocalOperation(db, SyncOperationType.createPickupPoint.value);
  final latency = await _syncCondition(
    condition,
    remote,
    () => repository.syncPending(includeFailed: true, force: true),
  );
  await _settle(condition);
  final operation = await _latestOperation(db, SyncOperationType.createPickupPoint.value);
  return EmulatorResult(
    condition: condition,
    flow: 'crear_punto_recojo_emulador',
    attempt: attempt,
    localSaved: localSaved,
    synced: operation?.state == SyncOperationState.synced.value,
    latencyMs: latency.inMilliseconds,
    attempts: operation?.attempts ?? 0,
    finalState: operation?.state ?? 'missing',
  );
}

Future<void> _cleanExperimentRows(AppDatabase db) async {
  await (db.delete(db.syncOperations)..where((row) => row.ownerUsername.equals(_owner))).go();
  await (db.delete(db.cachedFarmerProducts)..where((row) => row.ownerUsername.equals(_owner))).go();
  await (db.delete(db.cachedPickupPoints)..where((row) => row.ownerUsername.equals(_owner))).go();
}

Future<bool> _hasLocalOperation(AppDatabase db, String operationType) async {
  final row = await _latestOperation(db, operationType);
  return row != null;
}

Future<SyncOperation?> _latestOperation(AppDatabase db, String operationType) {
  return (db.select(db.syncOperations)
        ..where((row) => row.ownerUsername.equals(_owner) & row.operationType.equals(operationType))
        ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
        ..limit(1))
      .getSingleOrNull();
}

Future<Duration> _syncCondition(
  EmulatorCondition condition,
  EmulatorNetworkRemote remote,
  Future<void> Function() sync,
) async {
  _setSession(syncEnabled: true);
  remote.prepare(condition);
  final stopwatch = Stopwatch()..start();
  await sync();
  if (condition == EmulatorCondition.intermittent) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await sync();
  }
  stopwatch.stop();
  return stopwatch.elapsed;
}

Future<void> _settle(EmulatorCondition condition) async {
  if (condition == EmulatorCondition.intermittent) {
    await Future<void>.delayed(const Duration(milliseconds: 2300));
  }
}

void _setSession({required bool syncEnabled}) {
  SessionManager().clearSession();
  SessionManager().setSession(
    token: 'emulator-token',
    username: _owner,
    rol: syncEnabled ? 'AGRICULTOR' : 'TEST',
  );
}

Map<String, dynamic> _productPayload(String name) => {
  'name': name,
  'category': 'FRUTAS',
  'saleFormats': [
    {
      'saleFormat': 'KILO',
      'price': 8.0,
      'stock': 18,
      'referenceUnitWeightKg': 1,
    },
  ],
};

Map<String, dynamic> _pointPayload(String name) {
  final delivery = DateTime.now().add(const Duration(days: 5));
  final deadline = DateTime.now().add(const Duration(days: 3));
  String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
  return {
    'name': name,
    'address': 'Av. Emulador 123',
    'deliveryDate': date(delivery),
    'availableFrom': '10:00:00',
    'availableTo': '12:00:00',
    'orderDeadlineDate': date(deadline),
    'orderDeadlineTime': '15:00:00',
    'status': 'ACTIVE',
  };
}

String _rawCsv(List<EmulatorResult> results) {
  final rows = [
    'condition,flow,attempt,local_saved,synced,latency_ms,attempts,final_state',
    ...results.map(
      (item) => [
        item.condition.label,
        item.flow,
        item.attempt,
        item.localSaved,
        item.synced,
        item.latencyMs,
        item.attempts,
        item.finalState,
      ].map((value) => '"${value.toString().replaceAll('"', '""')}"').join(','),
    ),
  ];
  return '${rows.join('\n')}\n';
}

List<EmulatorSummary> _summarize(List<EmulatorResult> results) {
  return EmulatorCondition.values.map((condition) {
    final items = results.where((item) => item.condition == condition).toList();
    final local = items.where((item) => item.localSaved).length;
    final synced = items.where((item) => item.synced).length;
    final latencies = items.where((item) => item.synced).map((item) => item.latencyMs).toList();
    final avg = latencies.isEmpty ? 0.0 : latencies.reduce((a, b) => a + b) / latencies.length;
    return EmulatorSummary(
      condition: condition,
      flows: items.length,
      localRate: local / items.length * 100,
      syncRate: synced / local * 100,
      averageLatencyMs: avg,
    );
  }).toList();
}

String _summaryMarkdown(List<EmulatorSummary> summary, int total) {
  final buffer = StringBuffer()
    ..writeln('# Experimento offline-first - Parte B emulador')
    ..writeln()
    ..writeln('Operaciones ejecutadas dentro del emulador Android: $total')
    ..writeln()
    ..writeln('| Condicion de red | Flujos probados | Registro local completo | Tasa de sincronizacion exitosa | Latencia promedio de sincronizacion |')
    ..writeln('|---|---:|---:|---:|---:|');
  for (final item in summary) {
    buffer.writeln(
      '| ${item.condition.paperLabel} | ${item.flows} | '
      '${item.localRate.toStringAsFixed(1)}% | '
      '${item.syncRate.toStringAsFixed(1)}% | '
      '${(item.averageLatencyMs / 1000).toStringAsFixed(3)} s |',
    );
  }
  return buffer.toString();
}

enum EmulatorCondition {
  full,
  offline,
  intermittent;

  String get label => switch (this) {
    EmulatorCondition.full => 'conexion_completa',
    EmulatorCondition.offline => 'offline_total',
    EmulatorCondition.intermittent => 'conexion_intermitente',
  };

  String get paperLabel => switch (this) {
    EmulatorCondition.full => 'Conexion completa',
    EmulatorCondition.offline => 'Sin conexion (offline total)',
    EmulatorCondition.intermittent => 'Conexion intermitente',
  };
}

class EmulatorResult {
  const EmulatorResult({
    required this.condition,
    required this.flow,
    required this.attempt,
    required this.localSaved,
    required this.synced,
    required this.latencyMs,
    required this.attempts,
    required this.finalState,
  });

  final EmulatorCondition condition;
  final String flow;
  final int attempt;
  final bool localSaved;
  final bool synced;
  final int latencyMs;
  final int attempts;
  final String finalState;
}

class EmulatorSummary {
  const EmulatorSummary({
    required this.condition,
    required this.flows,
    required this.localRate,
    required this.syncRate,
    required this.averageLatencyMs,
  });

  final EmulatorCondition condition;
  final int flows;
  final double localRate;
  final double syncRate;
  final double averageLatencyMs;
}

abstract class EmulatorNetworkRemote {
  int failuresBeforeSuccess = 0;
  Duration latency = const Duration(milliseconds: 40);

  void prepare(EmulatorCondition condition) {
    failuresBeforeSuccess = condition == EmulatorCondition.intermittent ? 1 : 0;
    latency = switch (condition) {
      EmulatorCondition.full => const Duration(milliseconds: 30),
      EmulatorCondition.offline => const Duration(milliseconds: 60),
      EmulatorCondition.intermittent => const Duration(milliseconds: 110),
    };
  }

  Future<void> maybeFail() async {
    await Future<void>.delayed(latency);
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw Exception('intermittent emulator network drop');
    }
  }
}

class EmulatorImageStore implements LocalImageStore {
  const EmulatorImageStore(this.directory);

  final Directory directory;

  @override
  Future<String> preserve(File source, String localId) async {
    final target = File('${directory.path}/$localId.jpg');
    await source.copy(target.path);
    return target.path;
  }

  @override
  Future<void> deleteIfManaged(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class EmulatorProductRemote extends EmulatorNetworkRemote
    implements FarmerProductRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> listarProductosRaw() async => [];

  @override
  Future<Map<String, dynamic>> agregarProductoRaw(
    Map<String, dynamic> datos, {
    required File imageFile,
  }) async {
    await maybeFail();
    final id = datos['clientId']?.toString() ?? datos['id'].toString();
    return {
      ...datos,
      'id': id,
      'version': 0,
      'imageUrl': '/images/$id.jpg',
      'status': 'DISPONIBLE',
      'averageRating': 0,
      'reviewCount': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> modificarProductoRaw(
    String id,
    Map<String, dynamic> datos, {
    File? imageFile,
  }) async {
    await maybeFail();
    return {...datos, 'id': id, 'version': (datos['version'] as int? ?? 0) + 1};
  }

  @override
  Future<void> eliminarProducto(String id) async {
    await maybeFail();
  }
}

class EmulatorPickupPointRemote extends EmulatorNetworkRemote
    implements PickupPointRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> listarRaw() async => [];

  @override
  Future<Map<String, dynamic>> crearRaw(Map<String, dynamic> payload) async {
    await maybeFail();
    return {...payload, 'id': payload['clientId'], 'farmerUsername': _owner};
  }

  @override
  Future<Map<String, dynamic>> editarRaw(
    String id,
    Map<String, dynamic> payload,
  ) async {
    await maybeFail();
    return {...payload, 'id': id, 'farmerUsername': _owner};
  }

  @override
  Future<void> eliminar(String id) async {
    await maybeFail();
  }
}
