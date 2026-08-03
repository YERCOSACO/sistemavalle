import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Servicio encargado de realizar las peticiones a la API
// y gestionar el almacenamiento del token de autenticación.
class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);

  // URL base de la API. Se puede sobrescribir con:
  // flutter run --dart-define=API_BASE_URL=http://TU_IP:8000/api
  final String baseUrl =
  const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : _defaultBaseUrl();

  // Almacenamiento seguro para guardar el token del usuario
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000/api';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000/api';
    }
  }

  // Obtiene el token guardado en el dispositivo
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Construye las cabeceras necesarias para las peticiones HTTP.
  // Si existe un token, se agrega automáticamente al encabezado Authorization.
  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Realiza peticiones POST enviando datos en formato JSON
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    return await http
        .post(url, headers: headers, body: jsonEncode(data))
        .timeout(_requestTimeout);
  }

  // Realiza peticiones GET al servidor
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    return await http.get(url, headers: headers).timeout(_requestTimeout);
  }

  // Realiza peticiones PUT al servidor
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    return await http
        .put(url, headers: headers, body: jsonEncode(data))
        .timeout(_requestTimeout);
  }

  // Realiza peticiones DELETE al servidor
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    return await http.delete(url, headers: headers).timeout(_requestTimeout);
  }

  // Guarda el token recibido después de iniciar sesión
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Elimina el token almacenado al cerrar sesión
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}