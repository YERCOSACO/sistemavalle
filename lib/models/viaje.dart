import 'ruta.dart';
import 'bus.dart';

class Viaje {
  final int? id;
  final int rutaId;
  final int busId;
  final DateTime fechaViaje;
  final String horaSalida;
  final String estado;
  final Ruta? ruta;
  final Bus? bus;

  Viaje({
    this.id,
    required this.rutaId,
    required this.busId,
    required this.fechaViaje,
    required this.horaSalida,
    required this.estado,
    this.ruta,
    this.bus,
  });

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      id: json['id'] as int?,
      rutaId: json['ruta_id'] as int? ?? 0,
      busId: json['bus_id'] as int? ?? 0,
      fechaViaje: DateTime.tryParse(json['fecha_viaje']?.toString() ?? '') ?? DateTime.now(),
      horaSalida: json['hora_salida']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'programado',
      ruta: json['ruta'] != null ? Ruta.fromJson(json['ruta']) : null,
      bus: json['bus'] != null ? Bus.fromJson(json['bus']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ruta_id': rutaId,
      'bus_id': busId,
      'fecha_viaje': fechaViaje.toIso8601String().split('T')[0],
      'hora_salida': horaSalida,
      'estado': estado,
    };
  }
}
