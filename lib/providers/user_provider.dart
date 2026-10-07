import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/users');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _users = data.map((item) => User.fromJson(item)).toList();
      }
    } catch (e) { debugPrint('Error fetchUsers: $e'); }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveUser(User user) async {
    try {
      final response = user.id == null 
        ? await _apiService.post('/users', user.toJson())
        : await _apiService.put('/users/${user.id}', user.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUsers();
        return true;
      }
    } catch (e) { debugPrint('Error saveUser: $e'); }
    return false;
  }

  Future<bool> deleteUser(int id) async {
    try {
      final response = await _apiService.delete('/users/$id');
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) { debugPrint('Error deleteUser: $e'); }
    return false;
  }
}
