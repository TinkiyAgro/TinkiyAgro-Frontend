import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/courier/data/courier_delivery_repository.dart';
import '../../features/courier/data/courier_tracking_repository.dart';
import '../../features/farmer/data/farmer_product_repository.dart';
import '../../features/farmer/data/farmer_order_repository.dart';
import '../../features/farmer/data/pickup_point_repository.dart';
import '../session_manager.dart';
import '../evaluation/evaluation_analytics_service.dart';
import 'offline_metrics_exporter.dart';

class SyncCoordinator {
  SyncCoordinator._();

  static final SyncCoordinator instance = SyncCoordinator._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;
  DateTime? _lastFarmerPeriodicSync;

  void start() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        unawaited(syncNow());
      }
    });
    _periodicTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      final role = SessionManager().rol;
      if (role == 'REPARTIDOR') {
        unawaited(syncNow());
      } else if (role == 'AGRICULTOR') {
        final now = DateTime.now();
        final lastSync = _lastFarmerPeriodicSync;
        if (lastSync == null ||
            now.difference(lastSync) >= const Duration(minutes: 2)) {
          _lastFarmerPeriodicSync = now;
          unawaited(syncNow());
        }
      }
    });
  }

  Future<void> syncNow({bool force = false}) async {
    await EvaluationAnalyticsService.instance.syncPending();
    if (SessionManager().rol == 'AGRICULTOR') {
      _lastFarmerPeriodicSync = DateTime.now();
      await FarmerProductRepository.instance.syncPending(
        includeFailed: true,
        force: force,
      );
      await PickupPointRepository.instance.syncPending(
        includeFailed: true,
        force: force,
      );
      await FarmerOrderRepository.instance.syncPending(
        includeFailed: true,
        force: force,
      );
      try {
        await FarmerProductRepository.instance.refreshFromRemote();
      } catch (_) {
        // Connectivity is only a trigger; failed HTTP leaves local data intact.
      }
      try {
        await PickupPointRepository.instance.refreshFromRemote();
      } catch (_) {
        // Each cache refresh is independent.
      }
      try {
        await FarmerOrderRepository.instance.refreshFromRemote();
      } catch (_) {
        // Orders keep their last downloaded snapshot.
      }
    } else if (SessionManager().rol == 'REPARTIDOR') {
      await CourierTrackingRepository.instance.syncPending(
        includeFailed: true,
        force: force,
      );
      try {
        await CourierDeliveryRepository.instance.refreshFromRemote();
      } catch (_) {
        // Assigned deliveries keep their last downloaded snapshot.
      }
    }
    try {
      await const OfflineMetricsExporter().exportCsv();
    } catch (_) {
      // La sincronización no debe fallar si el archivo experimental no puede escribirse.
    }
  }
}
