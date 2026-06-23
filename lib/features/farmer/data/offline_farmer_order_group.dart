import '../../../core/offline/sync_types.dart';
import 'farmer_order_model.dart';

class OfflineFarmerOrderGroup {
  const OfflineFarmerOrderGroup({
    required this.group,
    required this.syncState,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  final FarmerOrderGroup group;
  final EntitySyncState syncState;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
}
