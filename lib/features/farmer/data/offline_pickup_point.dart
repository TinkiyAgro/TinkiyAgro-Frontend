import '../../../core/offline/sync_types.dart';
import 'pickup_point_model.dart';

class OfflinePickupPoint {
  const OfflinePickupPoint({
    required this.pickupPoint,
    required this.syncState,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  final PuntoRecojo pickupPoint;
  final EntitySyncState syncState;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
}
