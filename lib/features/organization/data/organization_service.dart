import 'dart:convert';
import 'dart:io';
import 'package:tinkiyagro_app/core/api_client.dart';

class OrganizationService {
  Future<Map<String, dynamic>> getOrganization() =>
      _getMap('/api/organizations/me');
  Future<List<Map<String, dynamic>>> getMembers() =>
      _getList('/api/organizations/me/members');
  Future<List<Map<String, dynamic>>> getProducts() =>
      _getList('/api/organizations/me/products');
  Future<List<Map<String, dynamic>>> getQuotes() =>
      _getList('/api/organizations/me/quotes');
  Future<List<Map<String, dynamic>>> getOrders() =>
      _getList('/api/organizations/me/orders');
  Future<Map<String, dynamic>> getOrder(String id) =>
      _getMap('/api/organizations/me/orders/$id');
  Future<Map<String, dynamic>> prepareOrder(String id) =>
      _post('/api/organizations/me/orders/$id/prepare', const {});
  Future<Map<String, dynamic>> dispatchOrder(
    String id,
    double latitude,
    double longitude,
    double accuracy,
  ) => _post('/api/organizations/me/orders/$id/dispatch', {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracy,
  });
  Future<Map<String, dynamic>> transitOrder(String id) =>
      _post('/api/organizations/me/orders/$id/transit', const {});
  Future<Map<String, dynamic>> getQuote(String id) =>
      _getMap('/api/organizations/me/quotes/$id');
  Future<Map<String, dynamic>> proposeQuote(
    String id,
    Map<String, dynamic> data,
  ) => _save('/api/organizations/me/quotes/$id/proposal', data, false);
  Future<Map<String, dynamic>> uploadProfileImage(File image) =>
      _upload('/api/organizations/me/profile-image', image);
  Future<Map<String, dynamic>> uploadProductImage(String id, File image) =>
      _upload('/api/organizations/me/products/$id/image', image);
  Future<Map<String, dynamic>> saveMember(
    Map<String, dynamic> data, {
    String? id,
  }) => _save(
    id == null
        ? '/api/organizations/me/members'
        : '/api/organizations/me/members/$id',
    data,
    id == null,
  );
  Future<Map<String, dynamic>> saveProduct(
    Map<String, dynamic> data, {
    String? id,
  }) => _save(
    id == null
        ? '/api/organizations/me/products'
        : '/api/organizations/me/products/$id',
    data,
    id == null,
  );

  Future<Map<String, dynamic>> getDiscoveryPreferences() =>
      _getMap('/api/discovery-preferences/me');
  Future<Map<String, dynamic>> saveDiscoveryPreferences(
    double lat,
    double lng,
    int radius,
  ) => _save('/api/discovery-preferences/me', {
    'latitude': lat,
    'longitude': lng,
    'radiusKm': radius,
  }, false);

  Future<Map<String, dynamic>> _getMap(String endpoint) async {
    final response = await ApiClient.get(endpoint);
    if (response.statusCode != 200)
      throw Exception('No se pudieron cargar los datos');
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> _getList(String endpoint) async {
    final response = await ApiClient.get(endpoint);
    if (response.statusCode != 200)
      throw Exception('No se pudieron cargar los datos');
    return (jsonDecode(response.body) as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> _save(
    String endpoint,
    Map<String, dynamic> data,
    bool create,
  ) async {
    final response = create
        ? await ApiClient.post(endpoint, data)
        : await ApiClient.put(endpoint, data);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      throw Exception(
        body is Map
            ? body['message'] ?? 'No se pudo guardar'
            : 'No se pudo guardar',
      );
    }
    return response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> _upload(String endpoint, File image) async {
    final response = await ApiClient.multipartPost(
      endpoint,
      image,
      field: 'image',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo subir la imagen');
    }
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.post(endpoint, data);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {}
      throw Exception(
        body is Map
            ? body['message'] ?? 'No se pudo completar la operación'
            : 'No se pudo completar la operación',
      );
    }
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }
}
