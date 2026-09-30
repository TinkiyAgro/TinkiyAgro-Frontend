import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../product_model.dart';
import '../../../reviews/data/review_model.dart';
import '../../../../core/evaluation/pilot_session.dart';

class CatalogService {
  Future<List<Producto>> buscarProductos({
    String? termino,
    String? categoria,
    double? precioMin,
    double? precioMax,
    double? calificacion,
    bool? ventaPorKilo,
    bool? ventaPorCaja,
  }) async {
    final params = <String, String>{};
    if (termino != null && termino.isNotEmpty) params['search'] = termino;
    // categoria debe ser el enum en mayúsculas: VERDURAS, FRUTAS, etc.
    if (categoria != null && categoria.isNotEmpty)
      params['category'] = categoria;
    if (precioMin != null) params['minPrice'] = precioMin.toString();
    if (precioMax != null) params['maxPrice'] = precioMax.toString();
    if (calificacion != null)
      params['minRating'] = calificacion.toInt().toString();
    if (ventaPorKilo == true) params['saleByKilo'] = 'true';
    if (ventaPorCaja == true) params['saleByBox'] = 'true';

    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.searchProductEndpoint}',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final endpoint = uri.toString().replaceFirst(AppConstants.baseUrl, '');
    debugPrint('[CatalogService] buscarProductos → $endpoint');
    final response = await ApiClient.get(endpoint);
    debugPrint(
      '[CatalogService] respuesta ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data;
      if (body is List) {
        data = body;
      } else if (body is Map) {
        data =
            (body['content'] ??
                    body['data'] ??
                    body['products'] ??
                    body['items'] ??
                    [])
                as List;
      } else {
        data = [];
      }
      final products = data
          .whereType<Map>()
          .map((e) => Producto.fromJson(e.cast<String, dynamic>()))
          .toList();
      return List.generate(
        products.length,
        (index) => products[index].copiarCon(
          sourceSection: 'POPULARES',
          sourcePosition: index + 1,
        ),
      );
    }
    throw Exception('Error al buscar productos: ${response.statusCode}');
  }

  Future<List<Producto>> obtenerRecomendados() async {
    final params = <String, String>{
      if (PilotSession.participantId.isNotEmpty)
        'participantId': PilotSession.participantId,
      if (PilotSession.sessionId.isNotEmpty)
        'pilotSessionId': PilotSession.sessionId,
      'sectionOrder': PilotSession.sectionOrder,
    };
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.recommendedProductEndpoint}',
    ).replace(queryParameters: params);
    final response = await ApiClient.get(
      uri.toString().replaceFirst(AppConstants.baseUrl, ''),
    );
    debugPrint(
      '[CatalogService] obtenerRecomendados ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 300))}',
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data;
      String? requestId;
      if (body is List) {
        data = body;
      } else if (body is Map) {
        requestId = body['requestId']?.toString();
        data =
            (body['content'] ??
                    body['data'] ??
                    body['products'] ??
                    body['items'] ??
                    [])
                as List;
      } else {
        data = [];
      }
      final products = data
          .whereType<Map>()
          .map((e) => Producto.fromJson(e.cast<String, dynamic>()))
          .toList();
      return List.generate(
        products.length,
        (index) => products[index].copiarCon(
          sourceSection: 'PARA_TI',
          sourcePosition: index + 1,
          recommendationRequestId: requestId,
        ),
      );
    }
    throw Exception('Error al obtener recomendados: ${response.statusCode}');
  }

  Future<List<Producto>> obtenerPopulares() async {
    final response = await ApiClient.get(AppConstants.popularProductEndpoint);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener populares: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    final data = body is List
        ? body
        : body is Map
        ? (body['products'] ?? body['content'] ?? body['data'] ?? []) as List
        : <dynamic>[];
    final products = data
        .whereType<Map>()
        .map((item) => Producto.fromJson(item.cast<String, dynamic>()))
        .toList();
    return List.generate(
      products.length,
      (index) => products[index].copiarCon(
        sourceSection: 'POPULARES',
        sourcePosition: index + 1,
      ),
    );
  }

  Future<Producto> obtenerDetalle(String id) async {
    final endpoint = AppConstants.productDetailConsumerEndpoint.replaceFirst(
      '{id}',
      id,
    );
    final response = await ApiClient.get(endpoint);
    if (response.statusCode == 200) {
      return Producto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(
      'Error al obtener detalle del producto: ${response.statusCode}',
    );
  }

  Future<List<Producto>> listarFavoritos() async {
    final response = await ApiClient.get(
      AppConstants.listFavoriteProductEndpoint,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al listar favoritos: ${response.statusCode}');
  }

  Future<void> agregarFavorito(String productId) async {
    final endpoint = AppConstants.addFavoriteProductEndpoint.replaceFirst(
      '{id}',
      productId,
    );
    final response = await ApiClient.post(endpoint, {});
    // Backend devuelve 204 No Content en éxito
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception('Error al agregar a favoritos: ${response.statusCode}');
    }
  }

  Future<void> quitarFavorito(String productId) async {
    final endpoint = AppConstants.removeFavoriteProductEndpoint.replaceFirst(
      '{id}',
      productId,
    );
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al quitar de favoritos: ${response.statusCode}');
    }
  }

  Future<List<Resena>> listarResenas(String productId) async {
    final endpoint = AppConstants.listReviewsEndpoint.replaceFirst(
      '{id}',
      productId,
    );
    final response = await ApiClient.get(endpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Resena.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al listar reseñas: ${response.statusCode}');
  }

  Future<bool> verificarCompra(String productId) async {
    try {
      final response = await ApiClient.get(AppConstants.listOrdersEndpoint);
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      final List<dynamic> orders = body is List
          ? body
          : (body['orders'] ?? body['content'] ?? body['data'] ?? []) as List;
      for (final order in orders.whereType<Map>()) {
        final subs =
            (order['subOrders'] ?? order['items'] ?? order['orders'] ?? [])
                as List;
        for (final sub in subs.whereType<Map>()) {
          final items =
              (sub['items'] ?? sub['products'] ?? order['items'] ?? []) as List;
          for (final item in items.whereType<Map>()) {
            final pid =
                item['productId']?.toString() ??
                item['product_id']?.toString() ??
                item['id']?.toString() ??
                '';
            if (pid == productId) return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<Resena> agregarResena(
    String productId,
    double rating,
    String content,
  ) async {
    final endpoint = AppConstants.addReviewEndpoint.replaceFirst(
      '{id}',
      productId,
    );
    debugPrint(
      '[CatalogService] agregarResena body: rating=$rating comment="$content"',
    );
    final response = await ApiClient.post(endpoint, {
      'rating': rating,
      'comment': content,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Resena.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al agregar reseña: ${response.statusCode}');
  }
}
