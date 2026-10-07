import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../services/api_service.dart';

class ReservaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Reserva> _reservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Reserva> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMisReservas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/mis-reservas');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List? ?? [];
        _reservas = data.map((item) => Reserva.fromJson(item)).toList();
      } else {
        _errorMessage = 'No se pudieron obtener las reservas';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> crearReserva(Map<String, dynamic> datosReserva) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/reservas', datosReserva);
      if (response.statusCode == 201) {
        await fetchMisReservas();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Error al crear reserva: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
