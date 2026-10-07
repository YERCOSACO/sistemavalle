import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tipo_encomienda.dart';
import '../services/api_service.dart';

class TipoEncomiendaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<TipoEncomienda> _tipos = [];
  bool _isLoading = false;

  List<TipoEncomienda> get tipos => _tipos;
  bool get isLoading => _isLoading;

  Future<void> fetchTipos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/tipo-encomiendas');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _tipos = data.map((item) => TipoEncomienda.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchTiposEncomienda: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveTipo(TipoEncomienda tipo) async {
    try {
      final response = tipo.id == null 
        ? await _apiService.post('/tipo-encomiendas', tipo.toJson())
        : await _apiService.put('/tipo-encomiendas/${tipo.id}', tipo.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTipos();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveTipoEncomienda: $e');
    }
    return false;
  }

  Future<bool> deleteTipo(int id) async {
    try {
      final response = await _apiService.delete('/tipo-encomiendas/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _tipos.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteTipoEncomienda: $e');
    }
    return false;
  }
}
