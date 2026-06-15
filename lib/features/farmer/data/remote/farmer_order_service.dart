import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../farmer_order_model.dart';

class FarmerOrderService {
  /// GET /api/farmer/orders/groups
  /// Returns all order groups for the farmer.
  Future<List<FarmerOrderGroup>> listarGrupos() async {
    debugPrint(
      '[FarmerOrderService] listarGrupos → ${AppConstants.groupOrdersEndpoint}',
    );
    final response = await ApiClient.get(AppConstants.groupOrdersEndpoint);
    debugPrint(
      '[FarmerOrderService] listarGrupos ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list =
            (body['groups'] ?? body['content'] ?? body['data'] ?? []) as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map>()
          .map((e) => FarmerOrderGroup.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    throw Exception('Error al listar grupos: ${response.statusCode}');
  }

  /// POST /api/farmer/orders/groups/dispatcher
  Future<void> asignarDespachador(
    List<String> subOrderIds,
    String dispatcherType, {
    String? courierUsername,
  }) async {
    final body = <String, dynamic>{
      'subOrderIds': subOrderIds,
      'dispatcherType': dispatcherType,
      if (courierUsername != null) 'courierUsername': courierUsername,
    };
    debugPrint('[FarmerOrderService] asignarDespachador body=$body');
    final response = await ApiClient.post(
      AppConstants.assignDispatcherEndpoint,
      body,
    );
    debugPrint(
      '[FarmerOrderService] asignarDespachador ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Error al asignar despachador: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// POST /api/farmer/orders/groups/dispatched
  Future<void> confirmarDespacho(List<String> subOrderIds) async {
    debugPrint(
      '[FarmerOrderService] confirmarDespacho subOrderIds=$subOrderIds',
    );
    final response = await ApiClient.post(
      AppConstants.subordersDispatchedEndpoint,
      {'subOrderIds': subOrderIds},
    );
    debugPrint(
      '[FarmerOrderService] confirmarDespacho ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Error al confirmar despacho: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// POST /api/farmer/orders/self-deliveries/{subOrderId}/confirm
  Future<void> confirmarEntrega(String subOrderId) async {
    final url = AppConstants.confirmDeliveryFarmerEndpoint.replaceAll('{subOrderId}', subOrderId);
    debugPrint('[FarmerOrderService] confirmarEntrega → $url');
    final response = await ApiClient.post(url, {'productsDelivered': true, 'paymentReceived': true});
    debugPrint('[FarmerOrderService] confirmarEntrega ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Error al confirmar entrega: ${response.statusCode} ${response.body}');
    }
  }

  /// GET /api/farmer/orders/couriers?query=...
  Future<List<RepartidorInfo>> buscarRepartidor(String query) async {
    final url = '${AppConstants.searchCourierEndpoint}?query=${Uri.encodeQueryComponent(query)}';
    debugPrint('[FarmerOrderService] buscarRepartidor → $url');
    final response = await ApiClient.get(url);
    debugPrint('[FarmerOrderService] buscarRepartidor ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = (body['couriers'] ?? body['content'] ?? body['data'] ?? []) as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map>()
          .map((e) => RepartidorInfo.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    throw Exception('Error al buscar repartidor: ${response.statusCode}');
  }

  /// POST /api/farmer/orders/groups/prepared
  Future<void> marcarPreparado(List<String> subOrderIds) async {
    debugPrint('[FarmerOrderService] marcarPreparado subOrderIds=$subOrderIds');
    final response = await ApiClient.post(AppConstants.preparedOrderEndpoint, {
      'subOrderIds': subOrderIds,
    });
    debugPrint(
      '[FarmerOrderService] marcarPreparado ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Error al marcar preparado: ${response.statusCode} ${response.body}',
      );
    }
  }
}
