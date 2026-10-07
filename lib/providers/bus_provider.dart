import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../services/api_service.dart';

class BusProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Bus> _buses = [];
  bool _isLoading = false;

  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;

  Future<void> fetchBuses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/buses');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _buses = data.map((item) => Bus.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchBuses: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveBus(Bus bus) async {
    try {
      final response = bus.id == null 
        ? await _apiService.post('/buses', bus.toJson())
        : await _apiService.put('/buses/${bus.id}', bus.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBuses();
        return true;
      }
    } catch (e) {
      debugPrint('Error saveBus: $e');
    }
    return false;
  }

  Future<bool> deleteBus(int id) async {
    try {
      final response = await _apiService.delete('/buses/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _buses.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteBus: $e');
    }
    return false;
  }
}
