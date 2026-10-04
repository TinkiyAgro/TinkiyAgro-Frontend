import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import '../order_model.dart';

class DeliveryOptionsService {
  /// GET /api/orders/checkout/options
  /// Returns farmers + delivery options for the current cart.
  Future<List<CheckoutFarmerOptions>> obtenerCheckoutOptions() async {
    debugPrint(
      '[DeliveryOptionsService] checkoutOptions → ${AppConstants.checkoutOptionsEndpoint}',
    );
    final response = await ApiClient.get(AppConstants.checkoutOptionsEndpoint);
    debugPrint(
      '[DeliveryOptionsService] checkoutOptions ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      return _parseFarmerList(jsonDecode(response.body));
    }
    throw Exception('checkoutOptions error: ${response.statusCode}');
  }

  /// GET /api/delivery/checkout/farmers/{farmerUsername}/options
  /// Returns delivery options + embedded pickup points for one farmer.
  Future<DeliveryOptions> obtenerOpciones(String farmerUsername) async {
    final endpoint = AppConstants.showDeliveryOptionsEndpoint.replaceFirst(
      '{farmerUsername}',
      farmerUsername,
    );
    debugPrint(
      '[DeliveryOptionsService] obtenerOpciones($farmerUsername) → $endpoint',
    );
    final response = await ApiClient.get(endpoint);
    debugPrint(
      '[DeliveryOptionsService] ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        final list = _parseFarmerList(body);
        return list.isNotEmpty
            ? list.first.toDeliveryOptions()
            : const DeliveryOptions(options: []);
      }
      return DeliveryOptions.fromJson(body as Map<String, dynamic>);
    }
    throw Exception('obtenerOpciones error: ${response.statusCode}');
  }

  /// POST /api/orders/checkout/payment-options
  /// Returns available payment methods (and optionally totals) per farmer.
  Future<PaymentSummary> obtenerPaymentOptions(
    List<CheckoutFarmer> farmers,
  ) async {
    final payload = {
      'farmers': farmers.map((f) {
        final method = f.tipoEntrega == 'Recojo' ? 'PICKUP' : 'DELIVERY';
        return <String, dynamic>{
          'farmerUsername': f.farmerUsername,
          'deliveryMethod': method,
          if (method == 'PICKUP' && f.selectedPickupPoint != null)
            'pickupPointId': f.selectedPickupPoint,
          if (method == 'DELIVERY' && f.selectedAddressId != null)
            'addressId': f.selectedAddressId,
        };
      }).toList(),
    };
    debugPrint(
      '[DeliveryOptionsService] paymentOptions → ${AppConstants.paymentOptionsEndpoint}',
    );
    final response = await ApiClient.post(
      AppConstants.paymentOptionsEndpoint,
      payload,
    );
    debugPrint(
      '[DeliveryOptionsService] paymentOptions ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PaymentSummary.fromJson(body);
      }
      if (body is List) {
        return PaymentSummary.fromJson({'paymentMethods': body});
      }
    }
    return const PaymentSummary(paymentMethods: ['Efectivo']);
  }

  static List<CheckoutFarmerOptions> _parseFarmerList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => CheckoutFarmerOptions.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final list = body['farmers'] ?? body['options'] ?? body['data'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map(
              (e) => CheckoutFarmerOptions.fromJson(e.cast<String, dynamic>()),
            )
            .toList();
      }
      return [CheckoutFarmerOptions.fromJson(body)];
    }
    return [];
  }
}

class CheckoutFarmerOptions {
  final String farmerUsername;
  final String farmerDisplayName;
  final String farmerAvatarUrl;
  final List<DeliveryOption> options;
  final double productsSubtotal;
  final List<String> paymentMethods; // per-farmer: ['Efectivo', 'Yape']

  const CheckoutFarmerOptions({
    required this.farmerUsername,
    required this.farmerDisplayName,
    required this.farmerAvatarUrl,
    required this.options,
    this.productsSubtotal = 0.0,
    this.paymentMethods = const [],
  });

  factory CheckoutFarmerOptions.fromJson(Map<String, dynamic> json) {
    final username = json['farmerUsername']?.toString() ?? '';
    final name =
        json['farmerName']?.toString() ??
        json['farmerDisplayName']?.toString() ??
        json['displayName']?.toString() ??
        username;
    final avatar = resolveMediaUrl(
      json['farmerAvatarUrl']?.toString() ??
          json['avatarUrl']?.toString() ??
          '',
    );
    final subtotal = _d(
      json['subtotal'] ?? json['productsSubtotal'] ?? json['productsTotal'],
    );

    // Parse per-farmer payment methods
    final rawPm =
        json['paymentMethods'] ?? json['acceptedPaymentMethods'] ?? const [];
    final pm = <String>[];
    if (rawPm is List) {
      for (final m in rawPm) {
        final s =
            (m is Map ? (m['type'] ?? m['method']) : m)
                ?.toString()
                .toUpperCase() ??
            '';
        if (s == 'YAPE' || s == 'YAPE_PAY') {
          pm.add('Yape');
        } else if (s == 'CASH' || s == 'EFECTIVO') {
          pm.add('Efectivo');
        } else if (s.isNotEmpty) {
          pm.add(s);
        }
      }
    }

    final opts = <DeliveryOption>[];
    final pickupPoints = parseCheckoutPickupPoints(json['pickupPoints']);
    final rawOptions =
        json['options'] ?? json['deliveryOptions'] ?? json['methods'];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          final option = DeliveryOption.fromJsonOption(o);
          if (option.type == 'PICKUP') {
            final points = option.pickupPoints.isNotEmpty
                ? option.pickupPoints
                : pickupPoints;
            if (points.isNotEmpty) opts.add(option.withPickupPoints(points));
          } else if (option.type != 'DISABLED') {
            opts.add(option);
          }
        }
      }
    }

    // Flat format fallback
    if (opts.isEmpty) {
      final pk = _d(json['pickupCost'] ?? json['pickup_cost']);
      final dl = _d(json['deliveryCost'] ?? json['delivery_cost']);
      if ((pk > 0 || json.containsKey('pickupCost')) &&
          pickupPoints.isNotEmpty) {
        opts.add(
          DeliveryOption(type: 'PICKUP', cost: pk, pickupPoints: pickupPoints),
        );
      }
      if (dl > 0 || json.containsKey('deliveryCost')) {
        opts.add(DeliveryOption(type: 'DELIVERY', cost: dl));
      }
    }

    return CheckoutFarmerOptions(
      farmerUsername: username,
      farmerDisplayName: name,
      farmerAvatarUrl: avatar,
      options: opts,
      productsSubtotal: subtotal,
      paymentMethods: pm,
    );
  }

  DeliveryOptions toDeliveryOptions() => DeliveryOptions(
    farmerDisplayName: farmerDisplayName,
    farmerAvatarUrl: farmerAvatarUrl,
    options: options,
  );
}

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
