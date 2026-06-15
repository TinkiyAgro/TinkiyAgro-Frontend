import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../order_model.dart';

class DeliveryOptionsService {
  /// GET /api/orders/checkout/options
  /// Returns farmers + delivery options for the current cart.
  Future<List<CheckoutFarmerOptions>> obtenerCheckoutOptions() async {
    debugPrint('[DeliveryOptionsService] checkoutOptions → ${AppConstants.checkoutOptionsEndpoint}');
    final response = await ApiClient.get(AppConstants.checkoutOptionsEndpoint);
    debugPrint('[DeliveryOptionsService] checkoutOptions ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      return _parseFarmerList(jsonDecode(response.body));
    }
    throw Exception('checkoutOptions error: ${response.statusCode}');
  }

  /// GET /api/delivery/checkout/farmers/{farmerUsername}/options
  /// Returns delivery options + embedded pickup points for one farmer.
  Future<DeliveryOptions> obtenerOpciones(String farmerUsername) async {
    final endpoint = AppConstants.showDeliveryOptionsEndpoint
        .replaceFirst('{farmerUsername}', farmerUsername);
    debugPrint('[DeliveryOptionsService] obtenerOpciones($farmerUsername) → $endpoint');
    final response = await ApiClient.get(endpoint);
    debugPrint('[DeliveryOptionsService] ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        final list = _parseFarmerList(body);
        return list.isNotEmpty ? list.first.toDeliveryOptions() : const DeliveryOptions(options: []);
      }
      return DeliveryOptions.fromJson(body as Map<String, dynamic>);
    }
    throw Exception('obtenerOpciones error: ${response.statusCode}');
  }

  /// GET /api/orders/checkout/payment-options
  /// Returns available payment methods and optionally totals.
  Future<PaymentSummary> obtenerPaymentOptions() async {
    debugPrint('[DeliveryOptionsService] paymentOptions → ${AppConstants.paymentOptionsEndpoint}');
    final response = await ApiClient.get(AppConstants.paymentOptionsEndpoint);
    debugPrint('[DeliveryOptionsService] paymentOptions ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PaymentSummary.fromJson(body);
      }
      // Array of payment method strings/objects
      if (body is List) {
        return PaymentSummary.fromJson({'paymentMethods': body});
      }
    }
    // Default: cash only (Yape only shown when API confirms it's configured)
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
            .map((e) => CheckoutFarmerOptions.fromJson(e.cast<String, dynamic>()))
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
  final double productsSubtotal; // if returned by checkoutOptionsEndpoint

  const CheckoutFarmerOptions({
    required this.farmerUsername,
    required this.farmerDisplayName,
    required this.farmerAvatarUrl,
    required this.options,
    this.productsSubtotal = 0.0,
  });

  factory CheckoutFarmerOptions.fromJson(Map<String, dynamic> json) {
    final username = json['farmerUsername']?.toString() ?? '';
    final name = json['farmerName']?.toString() ??
        json['farmerDisplayName']?.toString() ??
        json['displayName']?.toString() ??
        username;
    final avatar = json['farmerAvatarUrl']?.toString() ??
        json['avatarUrl']?.toString() ?? '';
    final subtotal = _d(json['subtotal'] ?? json['productsSubtotal'] ?? json['productsTotal']);

    final opts = <DeliveryOption>[];
    final rawOptions = json['options'] ?? json['deliveryOptions'];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          opts.add(DeliveryOption.fromJsonOption(o));
        }
      }
    }

    // Flat format fallback
    if (opts.isEmpty) {
      final pk = _d(json['pickupCost'] ?? json['pickup_cost']);
      final dl = _d(json['deliveryCost'] ?? json['delivery_cost']);
      if (pk > 0 || json.containsKey('pickupCost')) {
        opts.add(DeliveryOption(type: 'PICKUP', cost: pk));
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
