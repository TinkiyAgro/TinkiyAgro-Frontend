import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _token;
  String? _refreshToken;
  String? _rol;
  String? _username;
  String? _nombre;
  String? _apellido;
  String? _telefono;
  String? _email;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get rol => _rol;
  String? get username => _username;
  String? get nombre => _nombre;
  String? get apellido => _apellido;
  String? get telefono => _telefono;
  String? get email => _email;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  void setSession({
    String? token,
    String? refreshToken,
    String? rol,
    String? username,
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
  }) {
    if (token != null) _token = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (rol != null) _rol = rol.toUpperCase();
    if (username != null) _username = username;
    if (nombre != null) _nombre = nombre;
    if (apellido != null) _apellido = apellido;
    if (telefono != null) _telefono = telefono;
    if (email != null) _email = email;
    _saveToPrefs();
  }

  void clearSession() {
    _token = null;
    _refreshToken = null;
    _rol = null;
    _username = null;
    _nombre = null;
    _apellido = null;
    _telefono = null;
    _email = null;
    _clearPrefs();
  }

  /// Loads persisted session from SharedPreferences.
  /// Returns true if a valid session token was found.
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('s_token');
      _refreshToken = prefs.getString('s_refresh_token');
      _rol = prefs.getString('s_rol');
      _username = prefs.getString('s_username');
      _nombre = prefs.getString('s_nombre');
      _apellido = prefs.getString('s_apellido');
      _telefono = prefs.getString('s_telefono');
      _email = prefs.getString('s_email');
      return isLoggedIn;
    } catch (_) {
      return false;
    }
  }

  void _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) prefs.setString('s_token', _token!);
      if (_refreshToken != null) prefs.setString('s_refresh_token', _refreshToken!);
      if (_rol != null) prefs.setString('s_rol', _rol!);
      if (_username != null) prefs.setString('s_username', _username!);
      if (_nombre != null) prefs.setString('s_nombre', _nombre!);
      if (_apellido != null) prefs.setString('s_apellido', _apellido!);
      if (_telefono != null) prefs.setString('s_telefono', _telefono!);
      if (_email != null) prefs.setString('s_email', _email!);
    } catch (_) {}
  }

  void _clearPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('s_token');
      await prefs.remove('s_refresh_token');
      await prefs.remove('s_rol');
      await prefs.remove('s_username');
      await prefs.remove('s_nombre');
      await prefs.remove('s_apellido');
      await prefs.remove('s_telefono');
      await prefs.remove('s_email');
    } catch (_) {}
  }

  static Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }
}
