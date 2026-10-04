import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/features/orders/data/order_model.dart';

void main() {
  test('parses pickup and delivery from the methods response field', () {
    final options = DeliveryOptions.fromJson({
      'methods': [
        {'method': 'PICKUP', 'enabled': true, 'cost': 4.5},
        {'method': 'DELIVERY', 'enabled': true, 'cost': 8.0},
      ],
      'pickupPoints': [
        {
          'id': 'pickup-1',
          'name': 'Mercado central',
          'address': 'Av. Principal 123',
        },
      ],
    });

    expect(options.hasPickup, isTrue);
    expect(options.pickupCost, 4.5);
    expect(options.pickupOption!.pickupPoints.single.id, 'pickup-1');
    expect(options.hasDelivery, isTrue);
    expect(options.deliveryCost, 8.0);
  });

  test('does not expose disabled delivery methods', () {
    final options = DeliveryOptions.fromJson({
      'methods': [
        {'method': 'PICKUP', 'enabled': false, 'cost': 4.5},
        {'method': 'DELIVERY', 'enabled': true, 'cost': 8.0},
      ],
    });

    expect(options.hasPickup, isFalse);
    expect(options.hasDelivery, isTrue);
  });
}
