import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../order_model.dart';
import '../../../../core/evaluation/pilot_session.dart';

class OrderService {
  Future<void> acknowledgeTrackingReflection(
    String positionUpdateId,
    DateTime reflectedAt,
  ) async {
    if (PilotSession.sessionId.isEmpty) return;
    final endpoint = AppConstants.trackingReflectionEndpoint.replaceFirst(
      '{id}',
      positionUpdateId,
    );
    final response = await ApiClient.post(endpoint, {
      'reflectedAt': reflectedAt.toUtc().toIso8601String(),
      'participantId': PilotSession.participantId,
      'pilotSessionId': PilotSession.sessionId,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo registrar el reflejo GPS');
    }
  }

  /// GET /api/orders
  Future<List<PedidoConsumidor>> listarPedidos() async {
    debugPrint(
      '[OrderService] listarPedidos → ${AppConstants.listOrdersEndpoint}',
    );
    final response = await ApiClient.get(AppConstants.listOrdersEndpoint);
    debugPrint(
      '[OrderService] listarPedidos ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list =
            (body['orders'] ?? body['content'] ?? body['data'] ?? []) as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map>()
          .map((e) => PedidoConsumidor.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    throw Exception('Error al listar pedidos: ${response.statusCode}');
  }

  /// GET /api/orders/{id}
  Future<PedidoConsumidor> detallePedido(String id) async {
    final url = AppConstants.detailOrderEndpoint.replaceAll('{id}', id);
    debugPrint('[OrderService] detallePedido → $url');
    final response = await ApiClient.get(url);
    debugPrint(
      '[OrderService] detallePedido ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final Map<String, dynamic> map = body is Map
          ? body.cast<String, dynamic>()
          : {};
      return PedidoConsumidor.fromJson(map);
    }
    throw Exception('Error al obtener pedido: ${response.statusCode}');
  }

  /// POST /api/orders
  /// Sends the full checkout selections and confirms the order.
  Future<Map<String, dynamic>> confirmarPedido(
    List<CheckoutFarmer> farmers,
  ) async {
    final body = _buildPayload(farmers);
    debugPrint('[OrderService] confirmarPedido payload: ${jsonEncode(body)}');

    final response = await ApiClient.post(
      AppConstants.confirmOrderEndpoint,
      body,
    );
    debugPrint(
      '[OrderService] confirmarPedido ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {'status': 'ok'};
    }
    throw Exception(
      'Error al confirmar pedido: ${response.statusCode} ${response.body}',
    );
  }

  /// Obtiene la ubicación en tiempo real.
  /// [isCourier] = true → endpoint del repartidor; false → auto-entrega del agricultor.
  Future<TrackingInfo?> fetchTracking(
    String subOrderId, {
    bool isCourier = false,
  }) async {
    final endpoint = isCourier
        ? AppConstants.obtainUbicationCourierEndpoint
        : AppConstants.obtainUbicationFarmerEndpoint;
    final url = endpoint.replaceAll('{subOrderId}', subOrderId);
    debugPrint('[OrderService] fetchTracking(isCourier=$isCourier) → $url');
    try {
      final response = await ApiClient.get(url);
      debugPrint(
        '[OrderService] fetchTracking ${response.statusCode}: ${response.body}',
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final map = body is Map
            ? body.cast<String, dynamic>()
            : <String, dynamic>{};
        return TrackingInfo.fromJson(map);
      }
    } catch (e) {
      debugPrint('[OrderService] fetchTracking error: $e');
    }
    return null;
  }

  Map<String, dynamic> _buildPayload(List<CheckoutFarmer> farmers) {
    final list = farmers.map((f) {
      final method = f.tipoEntrega == 'Recojo' ? 'PICKUP' : 'DELIVERY';
      final payment = _toApiMethod(f.metodoPago);
      return {
        'farmerUsername': f.farmerUsername,
        'deliveryMethod': method,
        if (method == 'PICKUP' && f.selectedPickupPoint != null)
          'pickupPointId': f.selectedPickupPoint,
        if (method == 'DELIVERY' && f.selectedAddressId != null)
          'addressId': f.selectedAddressId,
        'paymentMethod': payment,
      };
    }).toList();

    return {'farmers': list};
  }

  static String _toApiMethod(String local) {
    switch (local.toLowerCase()) {
      case 'yape':
        return 'YAPE';
      case 'efectivo':
      default:
        return 'CASH';
    }
  }
}
