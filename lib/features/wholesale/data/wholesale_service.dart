import 'dart:convert';
import 'package:tinkiyagro_app/core/api_client.dart';

class WholesaleService {
  Future<List<Map<String, dynamic>>> products() =>
      _list('/api/wholesale/products');
  Future<List<Map<String, dynamic>>> quotes() => _list('/api/wholesale/quotes');
  Future<List<Map<String, dynamic>>> orders() => _list('/api/wholesale/orders');
  Future<Map<String, dynamic>> order(String id) =>
      _map('/api/wholesale/orders/$id');
  Future<Map<String, dynamic>> orderByQuote(String quoteId) =>
      _map('/api/wholesale/orders/by-quote/$quoteId');
  Future<Map<String, dynamic>> quote(String id) =>
      _map('/api/wholesale/quotes/$id');
  Future<Map<String, dynamic>> requestQuote(Map<String, dynamic> body) =>
      _send('/api/wholesale/quotes', body);
  Future<Map<String, dynamic>> acceptQuote(String id) =>
      _send('/api/wholesale/quotes/$id/accept', const {});
  Future<Map<String, dynamic>> rejectQuote(String id) =>
      _send('/api/wholesale/quotes/$id/reject', const {});
  Future<Map<String, dynamic>> deliverOrder(
    String id,
    double latitude,
    double longitude,
    double accuracy,
  ) => _send('/api/wholesale/orders/$id/deliver', {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracy,
  });
  Future<Map<String, dynamic>> reportIncident(String id, String notes) =>
      _send('/api/wholesale/orders/$id/incident', {'notes': notes});

  Future<List<Map<String, dynamic>>> _list(String endpoint) async {
    final r = await ApiClient.get(endpoint);
    if (r.statusCode != 200) throw Exception('No se pudieron cargar los datos');
    return (jsonDecode(r.body) as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> _map(String endpoint) async {
    final r = await ApiClient.get(endpoint);
    if (r.statusCode != 200) throw Exception('No se pudo cargar el detalle');
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> _send(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final r = await ApiClient.post(endpoint, body);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      dynamic decoded;
      try {
        decoded = jsonDecode(r.body);
      } catch (_) {}
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'No se pudo completar la operación'
            : 'No se pudo completar la operación',
      );
    }
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }
}
