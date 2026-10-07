import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ruta.dart';
import '../services/api_service.dart';

class RutaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Ruta> _rutas = [];
  bool _isLoading = false;

  List<Ruta> get rutas => _rutas;
  bool get isLoading => _isLoading;

  Future<void> fetchRutas() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/rutas');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _rutas = data.map((item) => Ruta.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchRutas: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRuta(Ruta ruta) async {
    try {
      final response = ruta.id == null 
        ? await _apiService.post('/rutas', ruta.toJson())
        : await _apiService.put('/rutas/${ruta.id}', ruta.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRutas();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveRuta: $e');
    }
    return false;
  }

  Future<bool> deleteRuta(int id) async {
    try {
      final response = await _apiService.delete('/rutas/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _rutas.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteRuta: $e');
    }
    return false;
  }
}
