import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/api_service.dart';

// Provider encargado de obtener y administrar la lista de clientes.
class ClienteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchClientes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/clientes');

      print("STATUS CLIENTES: ${response.statusCode}");
      print("BODY CLIENTES: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        _clientes = data.map((item) => Cliente.fromJson(item)).toList();
      } else {
        _errorMessage = _parseError(
          response.body,
          'No se pudo obtener clientes',
        );
      }
    } catch (e) {
      print("ERROR CLIENTES: $e");
      _errorMessage = 'Error al obtener clientes: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCliente(Cliente cliente) async {
    _errorMessage = null;
    try {
      final response = await _apiService.post('/clientes', cliente.toJson());
      if (response.statusCode == 201) {
        await fetchClientes();
        return true;
      }
      _errorMessage = _parseError(response.body, 'No se pudo crear el cliente');
    } catch (e) {
      debugPrint('Error createClientes: $e');
      _errorMessage = 'Error al crear el cliente: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> updateCliente(Cliente cliente) async {
    _errorMessage = null;
    try {
      final response = await _apiService.put(
        '/clientes/${cliente.id}',
        cliente.toJson(),
      );
      if (response.statusCode == 200) {
        await fetchClientes();
        return true;
      }
      _errorMessage = _parseError(
        response.body,
        'No se pudo actualizar el cliente',
      );
    } catch (e) {
      debugPrint('Error updateCliente: $e');
      _errorMessage = 'Error al actualizar el cliente: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> deleteCliente(int id) async {
    _errorMessage = null;
    try {
      final response = await _apiService.delete('/clientes/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _clientes.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      _errorMessage = _parseError(
        response.body,
        'No se pudo desactivar el cliente',
      );
    } catch (e) {
      debugPrint('Error DeleteCliente: $e');
      _errorMessage = 'Error al desactivar el cliente: $e';
    }
    notifyListeners();
    return false;
  }

  String _parseError(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }
}