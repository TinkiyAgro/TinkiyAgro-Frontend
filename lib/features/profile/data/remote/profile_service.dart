import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import '../address_model.dart';
import '../delivery_settings_model.dart';

class ProfileService {
  Future<List<Direccion>> listarDirecciones() async {
    final response = await ApiClient.get(AppConstants.listAddressEndpoint);
    debugPrint('[ProfileService] listarDirecciones ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data;
      if (body is List) {
        data = body;
      } else if (body is Map) {
        data = (body['addresses'] ?? body['content'] ?? body['data'] ?? []) as List;
      } else {
        data = [];
      }
      return data.map((e) => Direccion.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al listar direcciones: ${response.statusCode}');
  }

  Future<Direccion?> obtenerDireccionDefault() async {
    final response = await ApiClient.get(AppConstants.obtainAdressDefaultEndpoint);
    debugPrint('[ProfileService] obtenerDireccionDefault ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return Direccion.fromJson(body);
      }
      return null;
    }
    if (response.statusCode == 404) return null;
    throw Exception('Error al obtener dirección por defecto: ${response.statusCode}');
  }

  Future<Direccion> agregarDireccion({
    required String label,
    required String address,
    required String district,
    String reference = '',
    bool defaultAddress = false,
  }) async {
    final response = await ApiClient.post(AppConstants.addAddressEndpoint, {
      'label': label,
      'address': address,
      'district': district,
      'reference': reference,
      'defaultAddress': defaultAddress,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Direccion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al agregar dirección: ${response.statusCode}');
  }

  Future<void> eliminarDireccion(String id) async {
    final endpoint = AppConstants.deleteAddressEndpoint.replaceFirst('{id}', id);
    final response = await ApiClient.delete(endpoint);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar dirección: ${response.statusCode}');
    }
  }

  Future<Direccion> editarDireccion({
    required String id,
    required String label,
    required String address,
    required String district,
    String reference = '',
    bool defaultAddress = false,
  }) async {
    final endpoint = AppConstants.editAddressEndpoint.replaceFirst('{id}', id);
    final response = await ApiClient.put(endpoint, {
      'label': label,
      'address': address,
      'district': district,
      'reference': reference,
      'defaultAddress': defaultAddress,
    });
    if (response.statusCode == 200) {
      return Direccion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al editar dirección: ${response.statusCode}');
  }

  Future<ConfiguracionEntrega> obtenerConfiguracionEntrega() async {
    final response = await ApiClient.get(AppConstants.showDeliverySettingsEndpoint);
    if (response.statusCode == 200) {
      return ConfiguracionEntrega.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al obtener tarifas de entrega: ${response.statusCode}');
  }

  Future<ConfiguracionEntrega> guardarConfiguracionEntrega(ConfiguracionEntrega config) async {
    final response = await ApiClient.put(AppConstants.editDeliverySettingsEndpoint, config.toJson());
    if (response.statusCode == 200) {
      return ConfiguracionEntrega.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al guardar tarifas de entrega: ${response.statusCode}');
  }

  // ── Generic profile (consumer / driver) ──────────────────────────────────

  Future<Map<String, dynamic>> obtenerPerfil() async {
    final response = await ApiClient.get(AppConstants.showProfileEndpoint);
    debugPrint('[ProfileService] obtenerPerfil ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : {};
    }
    throw Exception('Error al obtener perfil: ${response.statusCode}');
  }

  Future<void> editarPerfil({
    required String firstName,
    required String lastName,
    required String phone,
    String description = '',
  }) async {
    final response = await ApiClient.put(AppConstants.editProfileEndpoint, {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phone,
      'description': description,
    });
    debugPrint('[ProfileService] editarPerfil ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al guardar perfil: ${response.statusCode}');
    }
  }

  // ── Farmer profile ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerPerfilAgricultor() async {
    final response = await ApiClient.get(AppConstants.showProfileFarmerEndpoint);
    debugPrint('[ProfileService] obtenerPerfilAgricultor ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : {};
    }
    throw Exception('Error al obtener perfil: ${response.statusCode}');
  }

  Future<void> editarPerfilAgricultor({
    required String firstName,
    required String lastName,
    required String phone,
    String description = '',
  }) async {
    final response = await ApiClient.put(AppConstants.editProfileFarmerEndpoint, {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phone,
      'description': description,
    });
    debugPrint('[ProfileService] editarPerfilAgricultor ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al guardar perfil: ${response.statusCode}');
    }
  }

  Future<void> cambiarContrasena({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await ApiClient.put(AppConstants.changePasswordEndpoint, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    debugPrint('[ProfileService] cambiarContrasena ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body);
      final msg = body is Map
          ? (body['message'] ?? body['error'] ?? 'Error al cambiar contraseña').toString()
          : 'Error al cambiar contraseña: ${response.statusCode}';
      throw Exception(msg);
    }
  }

  Future<void> subirFotoPerfil(File image) async {
    final response = await ApiClient.multipartPost(
      AppConstants.uploadProfilePhotoEndpoint,
      image,
      field: 'image',
    );
    debugPrint('[ProfileService] subirFotoPerfil ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Error al subir foto de perfil: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTransacciones() async {
    final response = await ApiClient.get(AppConstants.showTransactionsEndpoint);
    debugPrint('[ProfileService] obtenerTransacciones ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data;
      if (body is List) {
        data = body;
      } else if (body is Map) {
        data = (body['content'] ?? body['transactions'] ?? body['data'] ?? []) as List;
      } else {
        data = [];
      }
      return data.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception('Error al obtener transacciones: ${response.statusCode}');
  }

  // ── Farmer payment settings ───────────────────────────────────────────────

  Future<String?> obtenerNumeroYape() async {
    final response = await ApiClient.get(AppConstants.obtainPaymentSettingsEndpoint);
    debugPrint('[ProfileService] obtenerNumeroYape ${response.statusCode}: ${response.body}');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map) {
        return body['yapePhoneNumber']?.toString()
            ?? body['yapeNumber']?.toString()
            ?? body['yapeNumero']?.toString();
      }
    }
    return null;
  }

  Future<void> guardarConfiguracionPago({String? yapeNumber}) async {
    final numero = yapeNumber?.trim();
    final payload = <String, dynamic>{};
    if (numero != null && numero.isNotEmpty) {
      payload['yapePhoneNumber'] = numero;
    }
    final response = await ApiClient.put(AppConstants.editPaymentSettingsEndpoint, payload);
    debugPrint('[ProfileService] guardarConfiguracionPago ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al guardar método de pago: ${response.statusCode}');
    }
  }
}
