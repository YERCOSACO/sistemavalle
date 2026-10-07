import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asignacion_conductor.dart';
import '../services/api_service.dart';

class AsignacionConductorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Future<bool> asignarConductor(AsignacionConductor asignacion) async {
    try {
      final response = await _apiService.post('/asignacion-conductores', asignacion.toJson());
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error asignarConductor: $e');
      return false;
    }
  }

  Future<List<AsignacionConductor>> fetchAsignaciones(int viajeId) async {
    try {
      final response = await _apiService.get('/viajes/$viajeId/conductores');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        return data.map((item) => AsignacionConductor.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetchAsignaciones: $e');
    }
    return [];
  }
}
