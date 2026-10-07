import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/encomienda.dart';
import '../models/tipo_encomienda.dart';
import '../services/api_service.dart';

class EncomiendaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Encomienda> _encomiendas = [];
  List<TipoEncomienda> _tipos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Encomienda> get encomiendas => _encomiendas;
  List<TipoEncomienda> get tipos => _tipos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTipos() async {
    try {
      final response = await _apiService.get('/tipo-encomiendas');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        _tipos = data.map((item) => TipoEncomienda.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetchTipos: $e');
    }
  }

  Future<void> fetchMisEncomiendas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/mis-encomiendas');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        _encomiendas = data.map((item) => Encomienda.fromJson(item)).toList();
      } else {
        _errorMessage = 'No se pudieron cargar tus encomiendas';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTodas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.get('/encomiendas');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        _encomiendas = data.map((item) => Encomienda.fromJson(item)).toList();
      } else {
        _errorMessage = 'Error al cargar encomiendas';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registrarEncomienda(Encomienda encomienda) async {
    try {
      final response = await _apiService.post('/encomiendas', encomienda.toJson());
      if (response.statusCode == 201) {
        await fetchMisEncomiendas();
        return true;
      }
    } catch (e) {
      debugPrint('Error registrarEncomienda: $e');
    }
    return false;
  }

  Future<bool> updateEstado(int id, String nuevoEstado) async {
    try {
      final response = await _apiService.put('/encomiendas/$id/estado', {'estado': nuevoEstado});
      if (response.statusCode == 200) {
        await fetchTodas();
        return true;
      }
    } catch (e) {
      debugPrint('Error updateEstado: $e');
    }
    return false;
  }
}
