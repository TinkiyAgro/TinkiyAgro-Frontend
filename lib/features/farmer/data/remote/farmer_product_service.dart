import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import '../../../catalog/data/product_model.dart';

abstract interface class FarmerProductRemoteDataSource {
  Future<List<Map<String, dynamic>>> listarProductosRaw();
  Future<Map<String, dynamic>> agregarProductoRaw(
    Map<String, dynamic> datos, {
    required File imageFile,
  });
  Future<Map<String, dynamic>> modificarProductoRaw(
    String id,
    Map<String, dynamic> datos, {
    File? imageFile,
  });
  Future<void> eliminarProducto(String id);
}

class FarmerProductService implements FarmerProductRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> listarProductosRaw() async {
    final response = await ApiClient.get(AppConstants.listProductEndpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    throw Exception('Error al listar productos: ${response.statusCode}');
  }

  Future<List<Producto>> listarProductos() async {
    final data = await listarProductosRaw();
    return data.map(Producto.fromJson).toList();
  }

  Future<Producto> obtenerDetalle(String id) async {
    final endpoint = AppConstants.productDetailFarmerEndpoint.replaceFirst(
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

  Future<Producto> agregarProducto(
    Map<String, dynamic> datos, {
    required File imageFile,
  }) async {
    final data = await agregarProductoRaw(datos, imageFile: imageFile);
    return Producto.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> agregarProductoRaw(
    Map<String, dynamic> datos, {
    required File imageFile,
  }) {
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
    final data = await modificarProductoRaw(id, datos, imageFile: imageFile);
    return Producto.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> modificarProductoRaw(
    String id,
    Map<String, dynamic> datos, {
    File? imageFile,
  }) {
    final endpoint = AppConstants.modifyProductEndpoint.replaceFirst(
      '{id}',
      id,
    );
    return _sendMultipartProduct(
      method: 'PUT',
      endpoint: endpoint,
      datos: datos,
      imageFile: imageFile,
      imageRequired: false,
    );
  }

  @override
  Future<void> eliminarProducto(String id) async {
    final endpoint = AppConstants.deleteProductEndpoint.replaceFirst(
      '{id}',
      id,
    );
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar producto: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _sendMultipartProduct({
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
        return jsonDecode(responseBody) as Map<String, dynamic>;
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
}
