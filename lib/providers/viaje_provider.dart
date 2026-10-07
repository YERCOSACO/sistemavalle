import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/viaje.dart';
import '../services/api_service.dart';

class ViajeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Viaje> _viajes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Viaje> get viajes => _viajes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchViajes({String? origen, String? destino, String? fecha}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String query = '';
      if (origen != null) query += 'origen=$origen&';
      if (destino != null) query += 'destino=$destino&';
      if (fecha != null) query += 'fecha=$fecha&';
      
      final endpoint = '/viajes${query.isNotEmpty ? '?${query.substring(0, query.length - 1)}' : ''}';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        _viajes = data.map((item) => Viaje.fromJson(item)).toList();
      } else {
        _errorMessage = 'Error al buscar viajes: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchAsientos(int viajeId) async {
    try {
      final response = await _apiService.get('/viajes/$viajeId/asientos');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetchAsientos: $e');
    }
    return [];
  }

  Future<bool> saveViaje(Viaje viaje) async {
    try {
      final response = viaje.id == null
          ? await _apiService.post('/viajes', viaje.toJson())
          : await _apiService.put('/viajes/${viaje.id}', viaje.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await searchViajes();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveViaje: $e');
    }
    return false;
  }

  Future<bool> deleteViaje(int id) async {
    try {
      final response = await _apiService.delete('/viajes/$id');
      if (response.statusCode == 200) {
        _viajes.removeWhere((v) => v.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteViaje: $e');
    }
    return false;
  }
}
