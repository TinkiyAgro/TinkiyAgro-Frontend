import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import '../../../catalog/data/product_model.dart';

class FarmerProductService {
  Future<List<Producto>> listarProductos() async {
    final response = await ApiClient.get(AppConstants.listProductEndpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al listar productos: ${response.statusCode}');
  }

  Future<Producto> obtenerDetalle(String id) async {
    final endpoint = AppConstants.productDetailFarmerEndpoint.replaceFirst('{id}', id);
    final response = await ApiClient.get(endpoint);
    if (response.statusCode == 200) {
      return Producto.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al obtener detalle del producto: ${response.statusCode}');
  }

  Future<Producto> agregarProducto(
    Map<String, dynamic> datos, {
    required File imageFile,
  }) async {
    return _sendMultipartProduct(
      method: 'POST',
      endpoint: AppConstants.addProductEndpoint,
      datos: datos,
      imageFile: imageFile,
      imageRequired: true,
    );
  }

  Future<Producto> modificarProducto(
    String id,
    Map<String, dynamic> datos, {
    File? imageFile,
  }) async {
    final endpoint = AppConstants.modifyProductEndpoint.replaceFirst('{id}', id);
    return _sendMultipartProduct(
      method: 'PUT',
      endpoint: endpoint,
      datos: datos,
      imageFile: imageFile,
      imageRequired: false,
    );
  }

  Future<void> eliminarProducto(String id) async {
    final endpoint = AppConstants.deleteProductEndpoint.replaceFirst('{id}', id);
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar producto: ${response.statusCode}');
    }
  }
}
  Future<Producto> _sendMultipartProduct({
    required String method,
    required String endpoint,
    required Map<String, dynamic> datos,
    File? imageFile,
    required bool imageRequired,
  }) async {
    if (imageRequired && imageFile == null) {
      throw Exception('Debes seleccionar una imagen para continuar.');
    }

    final token = SessionManager().token;
    final request = http.MultipartRequest(
      method,
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromString(
        'product',
        jsonEncode(datos),
        contentType: MediaType('application', 'json'),
      ),
    );

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        return Producto.fromJson(
          jsonDecode(responseBody) as Map<String, dynamic>,
        );
      }

      throw Exception(
        'Error al ${method == 'POST' ? 'agregar' : 'modificar'} producto: '
        '${streamedResponse.statusCode}'
        '${responseBody.isNotEmpty ? ' - $responseBody' : ''}',
      );
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }
