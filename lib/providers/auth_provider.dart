import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _error;
  bool _isStaff = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isStaff => _isStaff;

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
        
        // El usuario puede venir en data['data']['user'] o data['data']
        final userData = authData['user'] != null 
            ? authData['user'] as Map<String, dynamic>
            : authData;

        await _apiService.saveToken(token!);
        _user = userData;
        _isAuthenticated = true;
        _checkIfStaff(userData);
        
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Error al iniciar sesión';
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión';
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  void _checkIfStaff(Map<String, dynamic>? user) {
    if (user == null) {
      _isStaff = false;
      return;
    }
    
    // Extraer nombre y email de forma segura sin importar la profundidad
    final String name = (user['name'] ?? user['usuario'] ?? '').toString().toLowerCase();
    final String email = (user['email'] ?? user['correo'] ?? '').toString().toLowerCase();
    
    bool hasAdminKeywords = name.contains('admin') || 
                           email.contains('admin') || 
                           email.contains('staff') ||
                           email.contains('vendedor') ||
                           email.contains('recepcion');

    bool hasRoleData = user['role'] != null || 
                       user['roles'] != null || 
                       user['role_id'] != null ||
                       (user['id'] != null && user['id'].toString() == '1');

    _isStaff = hasAdminKeywords || hasRoleData;
    debugPrint('SISTEMA: ¿Es Staff? $_isStaff');
  }

  Future<void> logout() async {
    try { await _apiService.post('/logout', {}); } catch (_) {}
    await _apiService.deleteToken();
    _isAuthenticated = false;
    _user = null;
    _isStaff = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    String? token = await _apiService.getToken();
    if (token == null) {
      _isAuthenticated = false;
      _isStaff = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiService.get('/me');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data'];
        
        // Si userData contiene una propiedad 'user', la usamos, si no, usamos userData directo
        if (userData is Map<String, dynamic>) {
          _user = userData['user'] != null ? userData['user'] : userData;
          _isAuthenticated = true;
          _checkIfStaff(_user);
        }
      } else {
        _isAuthenticated = false;
        _isStaff = false;
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    notifyListeners();
  }
}
