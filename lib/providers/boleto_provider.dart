import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/boleto.dart';
import '../services/api_service.dart';

class BoletoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Boleto> _boletos = [];
  bool _isLoading = false;

  List<Boleto> get boletos => _boletos;
  bool get isLoading => _isLoading;

  Future<void> fetchBoletos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/boletos');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _boletos = data.map((item) => Boleto.fromJson(item)).toList();
      }
    } catch (e) { debugPrint('Error fetchBoletos: $e'); }
    _isLoading = false;
    notifyListeners();
  }
}
