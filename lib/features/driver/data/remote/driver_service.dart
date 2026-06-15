import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../driver_model.dart';

class DriverService {
  /// GET /api/courier/deliveries
  Future<List<RepartidorDeliveryGroup>> listarEntregas() async {
    debugPrint('[DriverService] listarEntregas → ${AppConstants.listAssignedDeliveriesEndpoint}');
    final response = await ApiClient.get(AppConstants.listAssignedDeliveriesEndpoint);
    debugPrint('[DriverService] listarEntregas ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = (body['deliveries'] ?? body['content'] ?? body['data'] ?? []) as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map>()
          .map((e) => RepartidorDeliveryGroup.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    throw Exception('Error al listar entregas: ${response.statusCode}');
  }

  /// POST /api/courier/deliveries/{subOrderId}/confirm
  Future<void> confirmarEntrega(String subOrderId) async {
    final url = AppConstants.confirmDeliveryCourierEndpoint.replaceAll('{subOrderId}', subOrderId);
    debugPrint('[DriverService] confirmarEntrega → $url');
    final response = await ApiClient.post(url, {'productsDelivered': true, 'paymentReceived': true});
    debugPrint('[DriverService] confirmarEntrega ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception('Error al confirmar entrega: ${response.statusCode} ${response.body}');
    }
  }
}
