import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tipo_incidencia.dart';
import '../services/api_service.dart';

class TipoIncidenciaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TipoIncidencia> _tipos = [];
  bool _isLoading = false;

  List<TipoIncidencia> get tipos => _tipos;
  bool get isLoading => _isLoading;

  Future<void> fetchTipos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/tipo-incidencias');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _tipos = data.map((item) => TipoIncidencia.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchTiposIncidencia: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveTipo(TipoIncidencia tipo) async {
    try {
      final response = tipo.id == null 
        ? await _apiService.post('/tipo-incidencias', tipo.toJson())
        : await _apiService.put('/tipo-incidencias/${tipo.id}', tipo.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTipos();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveTipoIncidencia: $e');
    }
    return false;
  }

  Future<bool> deleteTipo(int id) async {
    try {
      final response = await _apiService.delete('/tipo-incidencias/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _tipos.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteTipoIncidencia: $e');
    }
    return false;
  }
}
