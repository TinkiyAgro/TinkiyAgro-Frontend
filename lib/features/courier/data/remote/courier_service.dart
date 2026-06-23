import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../courier_model.dart';

abstract interface class CourierRemoteDataSource {
  Future<List<Map<String, dynamic>>> listDeliveriesRaw();
  Future<Map<String, dynamic>> updateTrackingRaw(
    String subOrderId,
    Map<String, dynamic> payload,
  );
}

class CourierService implements CourierRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> listDeliveriesRaw() async {
    debugPrint(
      '[CourierService] listDeliveries → ${AppConstants.listAssignedDeliveriesEndpoint}',
    );
    final response = await ApiClient.get(
      AppConstants.listAssignedDeliveriesEndpoint,
    );
    debugPrint(
      '[CourierService] listDeliveries ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list =
            (body['deliveries'] ?? body['content'] ?? body['data'] ?? [])
                as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    throw Exception('Error al listar entregas: ${response.statusCode}');
  }

  /// GET /api/courier/deliveries
  Future<List<CourierDeliveryGroup>> listDeliveries() async {
    final list = await listDeliveriesRaw();
    return list.map(CourierDeliveryGroup.fromJson).toList();
  }

  @override
  Future<Map<String, dynamic>> updateTrackingRaw(
    String subOrderId,
    Map<String, dynamic> payload,
  ) async {
    final endpoint = AppConstants.updateTrackingCourierEndpoint.replaceFirst(
      '{subOrderId}',
      subOrderId,
    );
    final response = await ApiClient.post(endpoint, payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Error al actualizar tracking: ${response.statusCode} ${response.body}',
    );
  }

  /// POST /api/courier/deliveries/{subOrderId}/confirm
  Future<void> confirmDelivery(String subOrderId) async {
    final url = AppConstants.confirmDeliveryCourierEndpoint.replaceAll(
      '{subOrderId}',
      subOrderId,
    );
    debugPrint('[CourierService] confirmDelivery → $url');
    final response = await ApiClient.post(url, {
      'productsDelivered': true,
      'paymentReceived': true,
    });
    debugPrint(
      '[CourierService] confirmDelivery ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Error al confirmar entrega: ${response.statusCode} ${response.body}',
      );
    }
  }
}
