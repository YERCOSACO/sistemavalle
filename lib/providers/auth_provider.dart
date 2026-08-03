import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Provider encargado de manejar la autenticación del usuario.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/login', {
        'email': email,
        'password': password,
        'device_name': 'mobile_app',
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final authData = data['data'] as Map<String, dynamic>? ?? {};
        final token = authData['token']?.toString();
        final user = authData['user'];

        if (token == null || user is! Map<String, dynamic>) {
          _error = 'La respuesta del login no tiene el formato esperado';
          _isAuthenticated = false;
          notifyListeners();
          return false;
        }

        await _apiService.saveToken(token);
        _user = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Error al iniciar sesión';
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout', {});
    } catch (_) {}

    await _apiService.deleteToken();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    String? token = await _apiService.getToken();

    if (token != null) {
      try {
        final response = await _apiService.get('/me');
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          _user = data['data'] as Map<String, dynamic>?;
          _isAuthenticated = true;
        } else {
          await _apiService.deleteToken();
          _user = null;
          _isAuthenticated = false;
        }
      } catch (e) {
        _user = null;
        _isAuthenticated = false;
      }
    } else {
      _user = null;
      _isAuthenticated = false;
    }

    notifyListeners();
  }
}