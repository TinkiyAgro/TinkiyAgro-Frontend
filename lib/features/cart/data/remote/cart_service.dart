import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';

class ActiveCartResponse {
  final List<CartItemResponse> items;
  final double subtotal;
  final double costoEnvioEstimado;
  final double total;

  ActiveCartResponse({
    required this.items,
    required this.subtotal,
    required this.costoEnvioEstimado,
    required this.total,
  });

  factory ActiveCartResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ActiveCartResponse(
      items: rawItems
          .map((e) => CartItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      costoEnvioEstimado: (json['shippingCost'] ?? json['costoEnvioEstimado'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class CartItemResponse {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final String farmerUsername;
  final String farmerDisplayName;
  final String farmerAvatarUrl;
  final int cantidad;
  final String formato; // 'Kg' o 'Caja' para uso local
  final double precioUnitario;
  final double total;

  CartItemResponse({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.farmerUsername,
    required this.farmerDisplayName,
    required this.farmerAvatarUrl,
    required this.cantidad,
    required this.formato,
    required this.precioUnitario,
    required this.total,
  });

  factory CartItemResponse.fromJson(Map<String, dynamic> json) {
    final rawFormat = json['saleFormat']?.toString() ?? 'KILO';
    return CartItemResponse(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      farmerUsername: json['farmerUsername']?.toString() ?? '',
      farmerDisplayName: json['farmerName']?.toString() ??
          json['farmerDisplayName']?.toString() ?? '',
      farmerAvatarUrl: json['farmerAvatarUrl']?.toString() ??
          json['sellerAvatarUrl']?.toString() ?? '',
      cantidad: (json['quantity'] ?? 0) as int,
      formato: rawFormat == 'CAJA' ? 'Caja' : 'Kg',
      precioUnitario: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['subtotal'] ?? json['total'] ?? 0).toDouble(),
    );
  }
}

String _toSaleFormat(String formato) =>
    formato == 'Caja' ? 'CAJA' : 'KILO';

class CartService {
  Future<String> agregarAlCarrito({
    required String productId,
    required int cantidad,
    required String formato, // 'Kg' o 'Caja'
  }) async {
    final response = await ApiClient.post(AppConstants.addProductToCartEndpoint, {
      'productId': productId,
      'saleFormat': _toSaleFormat(formato),
      'quantity': cantidad,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Retorna el id del primer ítem que coincida (el carrito puede tener varios)
      final items = data['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        if (m['productId'] == productId &&
            m['saleFormat'] == _toSaleFormat(formato)) {
          return m['id']?.toString() ?? '';
        }
      }
      return data['id']?.toString() ?? '';
    }
    throw Exception('Error al agregar al carrito: ${response.statusCode}');
  }

  // La API solo permite cambiar la cantidad (no el formato)
  Future<void> modificarCantidad({
    required String itemId,
    required int cantidad,
  }) async {
    final endpoint = AppConstants.modifyCartItemEndpoint.replaceFirst('{id}', itemId);
    final response = await ApiClient.put(endpoint, {'quantity': cantidad});
    if (response.statusCode != 200) {
      throw Exception('Error al modificar ítem del carrito: ${response.statusCode}');
    }
  }

  Future<void> eliminarItem(String itemId) async {
    final endpoint = AppConstants.removeCartItemEndpoint.replaceFirst('{id}', itemId);
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar ítem del carrito: ${response.statusCode}');
    }
  }

  Future<ActiveCartResponse> verCarritoActivo() async {
    final response = await ApiClient.get(AppConstants.seeActiveCartEndpoint);
    debugPrint('[CartService] verCarritoActivo → ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      return ActiveCartResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al ver carrito activo: ${response.statusCode} ${response.body}');
  }

  Future<void> cerrarCarrito() async {
    // POST /api/cart/cerrar
    final response = await ApiClient.post(AppConstants.closeCartEndpoint, {});
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al cerrar el carrito: ${response.statusCode}');
    }
  }
}
