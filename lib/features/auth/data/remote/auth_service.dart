import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/login_request.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/login_dto.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/register_request.dart';

class AuthService {
  Future<InicioSesionDto> iniciarSesion(InicioSesionRequest request) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.loginEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return InicioSesionDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al iniciar sesión: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registrarUsuario(RegistroRequest request) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.registerEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Error al registrar usuario: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerPerfil(String token) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.profileEndpoint}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> actualizarPerfil({
    required String token,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.profileEndpoint}',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al guardar perfil: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No se pudo conectar al servidor.');
    }
  }

  /// Exchanges a refresh token for a new access token.
  Future<InicioSesionDto> refreshAccessToken(String refreshToken) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        return InicioSesionDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente.');
      }
    } on SocketException {
      throw Exception(
        'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    } catch (e) {
      rethrow;
    }
  }
}
