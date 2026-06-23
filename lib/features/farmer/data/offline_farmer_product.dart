import '../../catalog/data/product_model.dart';
import '../../../core/offline/sync_types.dart';

class OfflineFarmerProduct {
  const OfflineFarmerProduct({
    required this.product,
    required this.syncState,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  final Producto product;
  final EntitySyncState syncState;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;

  bool get isPending => syncState == EntitySyncState.pending;
}
