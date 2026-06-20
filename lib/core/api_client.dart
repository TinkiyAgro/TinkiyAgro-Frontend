import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:tinkiyagro_app/core/app_navigator.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';

class ApiClient {
  static bool _refreshing = false;

  static Map<String, String> _headers({String? overrideToken}) {
    final token = overrideToken ?? SessionManager().token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Tries to get a new access token using the stored refresh token.
  // Returns the new access token, or null if refresh failed.
  static Future<String?> _tryRefresh() async {
    if (_refreshing) return null;
    final refreshToken = SessionManager().refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    _refreshing = true;
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newToken = body['accessToken']?.toString() ?? body['token']?.toString();
        final newRefresh = body['refreshToken']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          SessionManager().setSession(token: newToken, refreshToken: newRefresh);
          debugPrint('[ApiClient] Token refreshed successfully');
          return newToken;
        }
      }
      debugPrint('[ApiClient] Refresh failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[ApiClient] Refresh error: $e');
    } finally {
      _refreshing = false;
    }
    return null;
  }

  static void _redirectToLogin() {
    SessionManager().clearSession();
    appNavigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/welcome', (_) => false);
  }

  static Future<http.Response> _withRetry(
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    final first = await call(_headers());
    debugPrint('[ApiClient] status=${first.statusCode} token=${SessionManager().token != null ? "present" : "NULL"}');
    if (first.statusCode == 401 || first.statusCode == 403) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        final retry = await call(_headers(overrideToken: newToken));
        debugPrint('[ApiClient] retry status=${retry.statusCode}');
        return retry;
      }
      // Refresh failed — session is fully expired, go to login
      _redirectToLogin();
    }
    return first;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] GET $url');
    try {
      return await _withRetry((h) => http.get(url, headers: h));
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] POST $url');
    try {
      return await _withRetry((h) => http.post(url, headers: h, body: jsonEncode(body)));
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] PUT $url');
    try {
      return await _withRetry((h) => http.put(url, headers: h, body: jsonEncode(body)));
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] PATCH $url');
    try {
      return await _withRetry((h) => http.patch(url, headers: h, body: jsonEncode(body)));
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] DELETE $url');
    try {
      return await _withRetry((h) => http.delete(url, headers: h));
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }

  static Future<http.Response> multipartPost(
    String endpoint,
    File file, {
    String field = 'file',
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    debugPrint('[ApiClient] MULTIPART POST $url field=$field path=${file.path}');
    final bytes = await file.readAsBytes();
    final ext = file.path.toLowerCase().split('.').last;
    final contentType = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'),
      'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'),
      'webp': MediaType('image', 'webp'),
    }[ext] ?? MediaType('image', 'jpeg');
    final filename = file.path.split('/').last;
    try {
      return await _withRetry((headers) async {
        final request = http.MultipartRequest('POST', url);
        final auth = headers['Authorization'];
        if (auth != null) request.headers['Authorization'] = auth;
        request.files.add(http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: contentType,
        ));
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      });
    } on SocketException {
      throw Exception('Sin conexión al servidor.');
    }
  }
}
