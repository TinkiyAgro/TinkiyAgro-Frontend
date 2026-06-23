import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../pickup_point_model.dart';

abstract interface class PickupPointRemoteDataSource {
  Future<List<Map<String, dynamic>>> listarRaw();
  Future<Map<String, dynamic>> crearRaw(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> editarRaw(
    String id,
    Map<String, dynamic> payload,
  );
  Future<void> eliminar(String id);
}

class PickupPointService implements PickupPointRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> listarRaw() async {
    final response = await ApiClient.get(AppConstants.listPickupPointsEndpoint);
    debugPrint(
      '[PickupPoint] listar → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => (item as Map).cast<String, dynamic>()).toList();
    }
    throw Exception('Error al listar puntos de recojo: ${response.statusCode}');
  }

  Future<List<PuntoRecojo>> listar() async {
    final list = await listarRaw();
    return list.map(PuntoRecojo.fromJson).toList();
  }

  Future<PuntoRecojo> obtener(String id) async {
    final endpoint = AppConstants.getPickupPointsEndpoint.replaceFirst(
      '{id}',
      id,
    );
    final response = await ApiClient.get(endpoint);
    if (response.statusCode == 200) {
      return PuntoRecojo.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al obtener punto de recojo: ${response.statusCode}');
  }

  Future<PuntoRecojo> crear({
    required String name,
    required String address,
    required String deliveryDate,
    required String availableFrom,
    required String availableTo,
    required String orderDeadlineDate,
    required String orderDeadlineTime,
    required String status,
  }) async {
    final data = await crearRaw({
      'name': name,
      'address': address,
      'deliveryDate': deliveryDate,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'orderDeadlineDate': orderDeadlineDate,
      'orderDeadlineTime': orderDeadlineTime,
      'status': status,
    });
    return PuntoRecojo.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> crearRaw(Map<String, dynamic> payload) async {
    final response = await ApiClient.post(
      AppConstants.createPickupPointsEndpoint,
      payload,
    );
    debugPrint(
      '[PickupPoint] crear → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Error al crear punto de recojo: ${response.statusCode} ${response.body}',
    );
  }

  Future<PuntoRecojo> editar({
    required String id,
    required String name,
    required String address,
    required String deliveryDate,
    required String availableFrom,
    required String availableTo,
    required String orderDeadlineDate,
    required String orderDeadlineTime,
    required String status,
  }) async {
    final data = await editarRaw(id, {
      'name': name,
      'address': address,
      'deliveryDate': deliveryDate,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'orderDeadlineDate': orderDeadlineDate,
      'orderDeadlineTime': orderDeadlineTime,
      'status': status,
    });
    return PuntoRecojo.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> editarRaw(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final endpoint = AppConstants.editPickupPointsEndpoint.replaceFirst(
      '{id}',
      id,
    );
    final response = await ApiClient.put(endpoint, payload);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Error al editar punto de recojo: ${response.statusCode} ${response.body}',
    );
  }

  @override
  Future<void> eliminar(String id) async {
    final endpoint = AppConstants.deletePickupPointsEndpoint.replaceFirst(
      '{id}',
      id,
    );
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Error al eliminar punto de recojo: ${response.statusCode}',
      );
    }
  }

  Future<List<PuntoRecojo>> listarActivos(String farmerUsername) async {
    final endpoint = AppConstants.listActivePickupPointsEndpoint.replaceFirst(
      '{farmerUsername}',
      farmerUsername,
    );
    final response = await ApiClient.get(endpoint);
    debugPrint(
      '[PickupPoint] listarActivos($farmerUsername) → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PuntoRecojo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al listar puntos activos: ${response.statusCode}');
  }
}
