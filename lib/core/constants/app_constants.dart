class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://tinkiyagro-api-a8fph4cmcxf4c5h4.eastus-01.azurewebsites.net',
  );

  //Auth
  static const String registerEndpoint = '/auth/register';

  static const String loginEndpoint = '/auth/login';

  static const String refreshTokenEndpoint = '/auth/refresh';

  static const String profileEndpoint = '/users/me';

  //Profile - General

  static const String showProfileEndpoint = '/api/profile/about-me';

  static const String editProfileEndpoint = '/api/profile/about-me';

  static const String changePasswordEndpoint = '/api/profile/password';

  static const String uploadProfilePhotoEndpoint = '/api/profile/profile-image';

  // Notifications

  static const String registerDeviceEndpoint = '/api/notifications/devices';

  static const String unregisterDeviceEndpoint = '/api/notifications/devices';

  static const String notificationsEndpoint = '/api/notifications';

  static const String markAllNotificationsReadEndpoint =
      '/api/notifications/read-all';

  //Profile - Customer

  static const String obtainAdressDefaultEndpoint =
      '/api/customer/profile/addresses/default';

  static const String addAddressEndpoint = '/api/customer/profile/addresses';

  static const String listAddressEndpoint = '/api/customer/profile/addresses';

  static const String deleteAddressEndpoint =
      '/api/customer/profile/addresses/{id}'; // + /{id}

  static const String editAddressEndpoint =
      '/api/customer/profile/addresses/{id}'; // + /{id}

  static const String showTransactionsEndpoint =
      '/api/customer/profile/transactions';

  //Profile - Farmer

  static const String showDeliverySettingsEndpoint =
      '/api/farmer/profile/delivery-settings';

  static const String editDeliverySettingsEndpoint =
      '/api/farmer/profile/delivery-settings';

  static const String obtainPaymentSettingsEndpoint =
      '/api/farmer/profile/payment-settings';

  static const String editPaymentSettingsEndpoint =
      '/api/farmer/profile/payment-settings';

  static const String showProfileFarmerEndpoint =
      '/api/farmer/profile/about-me';

  static const String editProfileFarmerEndpoint =
      '/api/farmer/profile/about-me';

  //Products
  static const String listProductEndpoint = '/api/farmer/products';

  static const String addProductEndpoint = '/api/farmer/products';

  static const String productDetailFarmerEndpoint =
      '/api/farmer/products/{id}'; // + /{id}

  static const String modifyProductEndpoint =
      '/api/farmer/products/{id}'; // + /{id}

  static const String deleteProductEndpoint =
      '/api/farmer/products/{id}'; // + /{id}

  static const String searchProductEndpoint = '/api/products';

  static const String productDetailConsumerEndpoint =
      '/api/products/{id}'; // + /{id}

  static const String recommendedProductEndpoint =
      '/api/products/recommended/evaluation';
  static const String popularProductEndpoint = '/api/products/popular';

  static const String evaluationEventsEndpoint = '/api/evaluation/events';
  static const String trackingReflectionEndpoint =
      '/api/evaluation/tracking/{id}/reflected';

  static const String listFavoriteProductEndpoint = '/api/products/favorites';

  static const String addFavoriteProductEndpoint =
      '/api/products/{id}/favorite';

  static const String removeFavoriteProductEndpoint =
      '/api/products/{id}/favorite'; // + /{id}

  static const String listReviewsEndpoint =
      '/api/products/{id}/reviews'; // + /{id}

  static const String addReviewEndpoint =
      '/api/products/{id}/reviews'; // + /{id}

  //Cart

  static const String addProductToCartEndpoint = '/api/cart/items';

  static const String modifyCartItemEndpoint =
      '/api/cart/items/{id}'; // + /{id}

  static const String removeCartItemEndpoint =
      '/api/cart/items/{id}'; // + /{id}

  static const String seeActiveCartEndpoint = '/api/cart';

  static const String deleteCartEndpoint = '/api/cart';

  static const String closeCartEndpoint = '/api/cart/cerrar';

  //Pickup Points

  static const String getPickupPointsEndpoint =
      '/api/farmer/pickup-points/{id}'; // + /{id}

  static const String editPickupPointsEndpoint =
      '/api/farmer/pickup-points/{id}'; // + /{id}

  static const String deletePickupPointsEndpoint =
      '/api/farmer/pickup-points/{id}'; // + /{id}

  static const String listPickupPointsEndpoint = '/api/farmer/pickup-points';

  static const String createPickupPointsEndpoint = '/api/farmer/pickup-points';

  static const String listActivePickupPointsEndpoint =
      '/api/farmers/{farmerUsername}/pickup-points';

  //Deliveries - Courier

  static const String updateDeliveryStatusCourierEndpoint =
      '/api/courier/deliveries/{subOrderId}/tracking'; // + /{id}

  static const String confirmDeliveryCourierEndpoint =
      '/api/courier/deliveries/{subOrderId}/confirm'; // + /{id}

  static const String listAssignedDeliveriesEndpoint =
      '/api/courier/deliveries';

  static const String obtainUbicationCourierEndpoint =
      '/api/courier/deliveries/{subOrderId}/tracking'; // + /{id}

  //Delivery - Checkout

  static const String showDeliveryOptionsEndpoint =
      '/api/delivery/checkout/farmers/{farmerUsername}/options'; // + /{farmerUsername}

  //Orders - Consumer

  static const String listOrdersEndpoint = '/api/orders';

  static const String confirmOrderEndpoint = '/api/orders';

  static const String detailOrderEndpoint = '/api/orders/{id}'; // + /{id}

  static const String checkoutOptionsEndpoint = '/api/orders/checkout/options';

  static const String paymentOptionsEndpoint =
      '/api/orders/checkout/payment-options';

  //Orders - Farmer

  static const String updateDeliveryStatusFarmerEndpoint =
      '/api/farmer/orders/self-deliveries/{subOrderId}/tracking'; // + /{orderId} + /{subOrderId}

  static const String confirmDeliveryFarmerEndpoint =
      '/api/farmer/orders/self-deliveries/{subOrderId}/confirm'; // + /{orderId} + /{subOrderId}

  static const String preparedOrderEndpoint =
      '/api/farmer/orders/groups/prepared';

  static const String assignDispatcherEndpoint =
      '/api/farmer/orders/groups/dispatcher';

  static const String subordersDispatchedEndpoint =
      '/api/farmer/orders/groups/dispatched';

  static const String showSelfDeliveriesEndpoint =
      '/api/farmer/orders/self-deliveries';

  static const String groupOrdersEndpoint = '/api/farmer/orders/groups';

  static const String searchCourierEndpoint = '/api/farmer/orders/couriers';

  static const String obtainUbicationFarmerEndpoint =
      '/api/farmer/orders/self-deliveries/{subOrderId}/tracking'; // + /{id}

  // Orders - Courier
  static const String updateTrackingCourierEndpoint =
      '/api/courier/deliveries/{subOrderId}/tracking';
}
