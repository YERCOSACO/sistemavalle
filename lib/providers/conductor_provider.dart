import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../services/api_service.dart';

class ConductorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Conductor> _conductores = [];
  bool _isLoading = false;

  List<Conductor> get conductores => _conductores;
  bool get isLoading => _isLoading;

  Future<void> fetchConductores() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/conductores');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _conductores = data.map((item) => Conductor.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchConductores: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveConductor(Conductor conductor) async {
    try {
      final response = conductor.id == null 
        ? await _apiService.post('/conductores', conductor.toJson())
        : await _apiService.put('/conductores/${conductor.id}', conductor.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchConductores();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveConductor: $e');
    }
    return false;
  }

  // Baja lógica: usa estado_base (0/1) en vez de un borrado físico
  Future<bool> deactivateConductor(int id) async {
    try {
      final response = await _apiService.delete('/conductores/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchConductores();
        return true;
      }
    } catch (e) {
      debugPrint('Error deactivateConductor: $e');
    }
    return false;
  }
}
