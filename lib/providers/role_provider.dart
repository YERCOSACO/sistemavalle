import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/role.dart';
import '../services/api_service.dart';

class RoleProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Role> _roles = [];
  bool _isLoading = false;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;

  Future<void> fetchRoles() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/roles');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _roles = data.map((item) => Role.fromJson(item)).toList();
      }
    } catch (e) { debugPrint('Error fetchRoles: $e'); }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRole(Role role) async {
    try {
      final response = role.id == null
        ? await _apiService.post('/roles', role.toJson())
        : await _apiService.put('/roles/${role.id}', role.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRoles();
        return true;
      }
    } catch (e) { debugPrint('Error saveRole: $e'); }
    return false;
  }

  Future<bool> deleteRole(int id) async {
    try {
      final response = await _apiService.delete('/roles/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _roles.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) { debugPrint('Error deleteRole: $e'); }
    return false;
  }
}
