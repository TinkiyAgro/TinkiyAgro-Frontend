import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/offline/app_database.dart';
import 'package:tinkiyagro_app/core/offline/image_store.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/courier/data/remote/courier_service.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_order_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/pickup_point_repository.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/farmer_order_service.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/farmer_product_service.dart';
import 'package:tinkiyagro_app/features/farmer/data/remote/pickup_point_service.dart';
import 'package:tinkiyagro_app/features/farmer/data/farmer_product_repository.dart';

const _repetitionsPerFlow = int.fromEnvironment(
  'OFFLINE_EXPERIMENT_REPETITIONS',
  defaultValue: 20,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline-first experiment generates CSV and summary', () async {
    final results = <ExperimentResult>[];
    for (final condition in NetworkCondition.values) {
      for (var attempt = 1; attempt <= _repetitionsPerFlow; attempt++) {
        results.add(await _runCreateProduct(condition, attempt));
        results.add(await _runUpdateProduct(condition, attempt));
        results.add(await _runCreatePickupPoint(condition, attempt));
        results.add(await _runMarkPrepared(condition, attempt));
      }
    }

    final outputDir = Directory('experiment_results');
    await outputDir.create(recursive: true);
    final rawCsv = File('${outputDir.path}/offline_first_part_a_raw.csv');
    await rawCsv.writeAsString(_rawCsv(results));
    final summary = _summarize(results);
    final summaryMd = File('${outputDir.path}/offline_first_part_a_summary.md');
    await summaryMd.writeAsString(_summaryMarkdown(summary, results.length));

    expect(results, hasLength(NetworkCondition.values.length * 4 * _repetitionsPerFlow));
    expect(results.where((item) => item.localSaved).length, results.length);
    expect(results.where((item) => item.synced).length, results.length);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<ExperimentResult> _runCreateProduct(
  NetworkCondition condition,
  int attempt,
) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final temp = await Directory.systemTemp.createTemp('tinkiyagro_exp_product');
  final remote = ExperimentProductRemote(condition);
  final repository = FarmerProductRepository.forTesting(
    database: db,
    remote: remote,
    images: ExperimentImageStore(temp),
  );
  try {
    _setFarmerSession(syncEnabled: false);
    final source = File('${temp.path}/source.jpg');
    await source.writeAsBytes([1, 2, 3]);
    await repository.createProduct(_productPayload('Producto offline $attempt'), imageFile: source);
    final localSaved = await _hasOperation(db, SyncOperationType.createProduct.value);
    final latency = await _syncFarmerCondition(
      condition,
      () => repository.syncPending(includeFailed: true, force: true),
      remote,
    );
    await _settleScheduledRetry(condition);
    final operation = await db.select(db.syncOperations).getSingle();
    return ExperimentResult(
      condition: condition,
      flow: 'crear_producto',
      attempt: attempt,
      localSaved: localSaved,
      synced: operation.state == SyncOperationState.synced.value,
      latencyMs: latency.inMilliseconds,
      attempts: operation.attempts,
      finalState: operation.state,
      error: operation.lastError,
    );
  } finally {
    await db.close();
    await temp.delete(recursive: true);
    SessionManager().clearSession();
  }
}

Future<ExperimentResult> _runUpdateProduct(
  NetworkCondition condition,
  int attempt,
) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final temp = await Directory.systemTemp.createTemp('tinkiyagro_exp_update');
  final remote = ExperimentProductRemote(condition)
    ..products = [_productJson(id: 'remote-product-$attempt', version: 1)];
  final repository = FarmerProductRepository.forTesting(
    database: db,
    remote: remote,
    images: ExperimentImageStore(temp),
  );
  try {
    _setFarmerSession(syncEnabled: true);
    await repository.refreshFromRemote();
    _setFarmerSession(syncEnabled: false);
    await repository.updateProduct('remote-product-$attempt', {
      ..._productPayload('Producto editado $attempt'),
      'version': 1,
      'saleFormats': [
        {
          'saleFormat': 'KILO',
          'price': 5.5,
          'stock': 30 + attempt,
          'referenceUnitWeightKg': 1,
        },
      ],
    });
    final localSaved = await _hasOperation(db, SyncOperationType.updateProduct.value);
    final latency = await _syncFarmerCondition(
      condition,
      () => repository.syncPending(includeFailed: true, force: true),
      remote,
    );
    await _settleScheduledRetry(condition);
    final operation = await db.select(db.syncOperations).getSingle();
    return ExperimentResult(
      condition: condition,
      flow: 'editar_producto_stock',
      attempt: attempt,
      localSaved: localSaved,
      synced: operation.state == SyncOperationState.synced.value,
      latencyMs: latency.inMilliseconds,
      attempts: operation.attempts,
      finalState: operation.state,
      error: operation.lastError,
    );
  } finally {
    await db.close();
    await temp.delete(recursive: true);
    SessionManager().clearSession();
  }
}

Future<ExperimentResult> _runCreatePickupPoint(
  NetworkCondition condition,
  int attempt,
) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final remote = ExperimentPickupPointRemote(condition);
  final repository = PickupPointRepository.forTesting(database: db, remote: remote);
  try {
    _setFarmerSession(syncEnabled: false);
    await repository.createPickupPoint(_pointPayload('Punto offline $attempt'));
    final localSaved = await _hasOperation(db, SyncOperationType.createPickupPoint.value);
    final latency = await _syncFarmerCondition(
      condition,
      () => repository.syncPending(includeFailed: true, force: true),
      remote,
    );
    await _settleScheduledRetry(condition);
    final operation = await db.select(db.syncOperations).getSingle();
    return ExperimentResult(
      condition: condition,
      flow: 'crear_punto_recojo',
      attempt: attempt,
      localSaved: localSaved,
      synced: operation.state == SyncOperationState.synced.value,
      latencyMs: latency.inMilliseconds,
      attempts: operation.attempts,
      finalState: operation.state,
      error: operation.lastError,
    );
  } finally {
    await db.close();
    SessionManager().clearSession();
  }
}

Future<ExperimentResult> _runMarkPrepared(
  NetworkCondition condition,
  int attempt,
) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final remote = ExperimentFarmerOrderRemote(condition)
    ..groups = [_groupJson(status: 'CONFIRMED', attempt: attempt)]
    ..preparedSnapshot = [_groupJson(status: 'PREPARED', attempt: attempt)];
  final repository = FarmerOrderRepository.forTesting(database: db, remote: remote);
  try {
    _setFarmerSession(syncEnabled: true);
    await repository.refreshFromRemote();
    final group = (await repository.watchGroups().first).single.group;
    _setFarmerSession(syncEnabled: false);
    await repository.markPrepared(group.id, ['sub-$attempt']);
    final localSaved = await _hasOperation(db, SyncOperationType.markOrderPrepared.value);
    final latency = await _syncFarmerCondition(
      condition,
      () => repository.syncPending(includeFailed: true, force: true),
      remote,
    );
    await _settleScheduledRetry(condition);
    final operation = await db.select(db.syncOperations).getSingle();
    return ExperimentResult(
      condition: condition,
      flow: 'marcar_pedido_preparado',
      attempt: attempt,
      localSaved: localSaved,
      synced: operation.state == SyncOperationState.synced.value,
      latencyMs: latency.inMilliseconds,
      attempts: operation.attempts,
      finalState: operation.state,
      error: operation.lastError,
    );
  } finally {
    await db.close();
    SessionManager().clearSession();
  }
}

Future<Duration> _syncFarmerCondition(
  NetworkCondition condition,
  Future<void> Function() sync,
  ExperimentNetworkRemote remote,
) async {
  _setFarmerSession(syncEnabled: true);
  remote.prepareFor(condition);
  final stopwatch = Stopwatch()..start();
  await sync();
  if (condition == NetworkCondition.intermittent) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await sync();
  }
  stopwatch.stop();
  return stopwatch.elapsed;
}

Future<void> _settleScheduledRetry(NetworkCondition condition) async {
  if (condition == NetworkCondition.intermittent) {
    await Future<void>.delayed(const Duration(milliseconds: 2300));
  }
}

Future<bool> _hasOperation(AppDatabase db, String type) async {
  final operation = await (db.select(
    db.syncOperations,
  )..where((row) => row.operationType.equals(type))).getSingleOrNull();
  return operation != null && operation.state != SyncOperationState.conflict.value;
}

void _setFarmerSession({required bool syncEnabled}) {
  SessionManager().clearSession();
  SessionManager().setSession(
    token: 'experiment-token',
    username: 'farmer_experiment',
    rol: syncEnabled ? 'AGRICULTOR' : 'TEST',
  );
}

Map<String, dynamic> _productPayload(String name) => {
  'name': name,
  'category': 'FRUTAS',
  'saleFormats': [
    {
      'saleFormat': 'KILO',
      'price': 7.5,
      'stock': 25,
      'referenceUnitWeightKg': 1,
    },
  ],
};

Map<String, dynamic> _productJson({required String id, int version = 0}) => {
  ..._productPayload('Piña experimental'),
  'id': id,
  'version': version,
  'imageUrl': '/images/$id.jpg',
  'status': 'DISPONIBLE',
  'averageRating': 0,
  'reviewCount': 0,
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
    'address': 'Av. Experimental 123',
    'deliveryDate': date(delivery),
    'availableFrom': '10:00:00',
    'availableTo': '12:00:00',
    'orderDeadlineDate': date(deadline),
    'orderDeadlineTime': '15:00:00',
    'status': 'ACTIVE',
  };
}

Map<String, dynamic> _groupJson({required String status, required int attempt}) {
  final groupKey = 'farmer_experiment:PICKUP:point-$attempt:2026-07-10:$status';
  return {
    'groupKey': groupKey,
    'deliveryMethod': 'PICKUP',
    'pickupPointName': 'Mercado Experimental',
    'destinationAddress': 'Av. Experimental 123',
    'pickupSchedule': 'Viernes 10/07/2026 10:00 - 12:00',
    'pickupFrom': '10:00:00',
    'pickupTo': '12:00:00',
    'status': status,
    'orderCount': 1,
    'total': 20.0,
    'itemsToPrepare': status == 'CONFIRMED'
        ? [
            {'productName': 'Piña', 'saleFormat': 'KILO', 'quantity': 2},
          ]
        : [],
    'customerOrders': [
      {
        'subOrderId': 'sub-$attempt',
        'customerUsername': 'customer',
        'customerName': 'Cliente Experimental',
        'total': 20.0,
        'items': [
          {
            'productName': 'Piña',
            'saleFormat': 'KILO',
            'quantity': 2,
            'unitPrice': 10.0,
          },
        ],
      },
    ],
    'subOrders': [
      {
        'id': 'sub-$attempt',
        'customerUsername': 'customer',
        'customerName': 'Cliente Experimental',
        'deliveryMethod': 'PICKUP',
        'paymentMethod': 'CASH',
        'status': status,
        'productsTotal': 20.0,
        'deliveryCost': 0.0,
        'total': 20.0,
        'items': [
          {
            'productName': 'Piña',
            'saleFormat': 'KILO',
            'quantity': 2,
            'unitPrice': 10.0,
          },
        ],
      },
    ],
  };
}

String _rawCsv(List<ExperimentResult> results) {
  final rows = [
    'condition,flow,attempt,local_saved,synced,latency_ms,attempts,final_state,error',
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
        item.error ?? '',
      ].map(_csvCell).join(','),
    ),
  ];
  return '${rows.join('\n')}\n';
}

String _csvCell(Object? value) {
  final text = value.toString().replaceAll('"', '""');
  return '"$text"';
}

List<ExperimentSummary> _summarize(List<ExperimentResult> results) {
  return NetworkCondition.values.map((condition) {
    final items = results.where((item) => item.condition == condition).toList();
    final local = items.where((item) => item.localSaved).length;
    final synced = items.where((item) => item.synced).length;
    final latencies = items
        .where((item) => item.synced)
        .map((item) => item.latencyMs)
        .toList();
    final avg = latencies.isEmpty
        ? 0.0
        : latencies.reduce((a, b) => a + b) / latencies.length;
    return ExperimentSummary(
      condition: condition,
      flows: items.length,
      localRate: local / items.length * 100,
      syncRate: synced / local * 100,
      averageLatencyMs: avg,
    );
  }).toList();
}

String _summaryMarkdown(List<ExperimentSummary> summary, int total) {
  final buffer = StringBuffer()
    ..writeln('# Experimento offline-first - Parte A')
    ..writeln()
    ..writeln('Operaciones controladas ejecutadas: $total')
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

enum NetworkCondition {
  full,
  offline,
  intermittent;

  String get label => switch (this) {
    NetworkCondition.full => 'conexion_completa',
    NetworkCondition.offline => 'offline_total',
    NetworkCondition.intermittent => 'conexion_intermitente',
  };

  String get paperLabel => switch (this) {
    NetworkCondition.full => 'Conexion completa',
    NetworkCondition.offline => 'Sin conexion (offline total)',
    NetworkCondition.intermittent => 'Conexion intermitente',
  };
}

class ExperimentResult {
  const ExperimentResult({
    required this.condition,
    required this.flow,
    required this.attempt,
    required this.localSaved,
    required this.synced,
    required this.latencyMs,
    required this.attempts,
    required this.finalState,
    required this.error,
  });

  final NetworkCondition condition;
  final String flow;
  final int attempt;
  final bool localSaved;
  final bool synced;
  final int latencyMs;
  final int attempts;
  final String finalState;
  final String? error;
}

class ExperimentSummary {
  const ExperimentSummary({
    required this.condition,
    required this.flows,
    required this.localRate,
    required this.syncRate,
    required this.averageLatencyMs,
  });

  final NetworkCondition condition;
  final int flows;
  final double localRate;
  final double syncRate;
  final double averageLatencyMs;
}

abstract class ExperimentNetworkRemote {
  bool online = true;
  int failuresBeforeSuccess = 0;
  Duration latency = const Duration(milliseconds: 35);

  void prepareFor(NetworkCondition condition) {
    online = true;
    failuresBeforeSuccess = condition == NetworkCondition.intermittent ? 1 : 0;
    latency = switch (condition) {
      NetworkCondition.full => const Duration(milliseconds: 25),
      NetworkCondition.offline => const Duration(milliseconds: 45),
      NetworkCondition.intermittent => const Duration(milliseconds: 90),
    };
  }

  Future<void> maybeFail() async {
    await Future<void>.delayed(latency);
    if (!online) throw Exception('network unavailable');
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw Exception('intermittent network drop');
    }
  }
}

class ExperimentImageStore implements LocalImageStore {
  const ExperimentImageStore(this.directory);

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

class ExperimentProductRemote extends ExperimentNetworkRemote
    implements FarmerProductRemoteDataSource {
  ExperimentProductRemote(this.condition);

  final NetworkCondition condition;
  List<Map<String, dynamic>> products = [];

  @override
  Future<List<Map<String, dynamic>>> listarProductosRaw() async => products;

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
    final version = datos['version'] as int? ?? 0;
    return {
      ...datos,
      'id': id,
      'version': version + 1,
      'imageUrl': datos['imageUrl'] ?? '/images/$id.jpg',
      'status': 'DISPONIBLE',
      'averageRating': 0,
      'reviewCount': 0,
    };
  }

  @override
  Future<void> eliminarProducto(String id) async {
    await maybeFail();
  }
}

class ExperimentPickupPointRemote extends ExperimentNetworkRemote
    implements PickupPointRemoteDataSource {
  ExperimentPickupPointRemote(this.condition);

  final NetworkCondition condition;

  @override
  Future<List<Map<String, dynamic>>> listarRaw() async => [];

  @override
  Future<Map<String, dynamic>> crearRaw(Map<String, dynamic> payload) async {
    await maybeFail();
    return {
      ...payload,
      'id': payload['clientId'],
      'farmerUsername': 'farmer_experiment',
    };
  }

  @override
  Future<Map<String, dynamic>> editarRaw(
    String id,
    Map<String, dynamic> payload,
  ) async {
    await maybeFail();
    return {...payload, 'id': id, 'farmerUsername': 'farmer_experiment'};
  }

  @override
  Future<void> eliminar(String id) async {
    await maybeFail();
  }
}

class ExperimentFarmerOrderRemote extends ExperimentNetworkRemote
    implements FarmerOrderRemoteDataSource {
  ExperimentFarmerOrderRemote(this.condition);

  final NetworkCondition condition;
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> preparedSnapshot = [];

  @override
  Future<List<Map<String, dynamic>>> listarGruposRaw() async => groups;

  @override
  Future<List<Map<String, dynamic>>> marcarPreparadoRaw(
    List<String> subOrderIds,
  ) async {
    await maybeFail();
    return preparedSnapshot;
  }
}

class ExperimentCourierRemote extends ExperimentNetworkRemote
    implements CourierRemoteDataSource {
  ExperimentCourierRemote(this.condition);

  final NetworkCondition condition;

  @override
  Future<List<Map<String, dynamic>>> listDeliveriesRaw() async => [];

  @override
  Future<Map<String, dynamic>> updateTrackingRaw(
    String subOrderId,
    Map<String, dynamic> payload,
  ) async {
    await maybeFail();
    return {'id': subOrderId, ...payload};
  }
}
