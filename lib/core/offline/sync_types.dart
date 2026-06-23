enum SyncOperationState { pending, syncing, synced, failed, conflict }

enum EntitySyncState { synced, pending, failed, conflict }

enum SyncOperationType {
  createProduct,
  updateProduct,
  deleteProduct,
  createPickupPoint,
  updatePickupPoint,
  deletePickupPoint,
  markOrderPrepared,
  updateTracking,
}

extension SyncOperationStateValue on SyncOperationState {
  String get value => name;
}

extension EntitySyncStateValue on EntitySyncState {
  String get value => name;
}

extension SyncOperationTypeValue on SyncOperationType {
  String get value => switch (this) {
    SyncOperationType.createProduct => 'CREATE_PRODUCT',
    SyncOperationType.updateProduct => 'UPDATE_PRODUCT',
    SyncOperationType.deleteProduct => 'DELETE_PRODUCT',
    SyncOperationType.createPickupPoint => 'CREATE_PICKUP_POINT',
    SyncOperationType.updatePickupPoint => 'UPDATE_PICKUP_POINT',
    SyncOperationType.deletePickupPoint => 'DELETE_PICKUP_POINT',
    SyncOperationType.markOrderPrepared => 'MARK_ORDER_PREPARED',
    SyncOperationType.updateTracking => 'UPDATE_TRACKING',
  };
}
