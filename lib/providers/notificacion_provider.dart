import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';

class NotificacionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = false;

  List<Notificacion> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;

  Future<void> fetchMisNotificaciones() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/mis-notificaciones');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _notificaciones = data.map((item) => Notificacion.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchNotificaciones: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> marcarLeida(int id) async {
    try {
      await _apiService.put('/notificaciones/$id/leer', {});
      final index = _notificaciones.indexWhere((n) => n.id == id);
      if (index != -1) {
        // En una app real, actualizaríamos el estado localmente
        await fetchMisNotificaciones();
      }
    } catch (e) {
      debugPrint('Error marcarLeida: $e');
    }
  }
}
