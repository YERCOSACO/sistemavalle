import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidencia_viaje.dart';
import '../services/api_service.dart';

class IncidenciaViajeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<IncidenciaViaje> _incidencias = [];
  bool _isLoading = false;

  List<IncidenciaViaje> get incidencias => _incidencias;
  bool get isLoading => _isLoading;

  Future<void> fetchIncidencias(int viajeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/viajes/$viajeId/incidencias');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _incidencias = data.map((item) => IncidenciaViaje.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchIncidencias: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveIncidencia(IncidenciaViaje incidencia) async {
    try {
      final response = incidencia.id == null 
        ? await _apiService.post('/incidencia-viajes', incidencia.toJson())
        : await _apiService.put('/incidencia-viajes/${incidencia.id}', incidencia.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Error saveIncidencia: $e');
    }
    return false;
  }
}
