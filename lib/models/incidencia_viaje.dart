class IncidenciaViaje {
  final int? id;
  final int viajeId;
  final int tipoIncidenciaId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? descripcionDetalle;

  IncidenciaViaje({
    this.id,
    required this.viajeId,
    required this.tipoIncidenciaId,
    required this.fechaInicio,
    this.fechaFin,
    this.descripcionDetalle,
  });

  factory IncidenciaViaje.fromJson(Map<String, dynamic> json) {
    return IncidenciaViaje(
      id: json['id'] as int?,
      viajeId: json['viaje_id'] as int? ?? 0,
      tipoIncidenciaId: json['tipo_incidencia_id'] as int? ?? 0,
      fechaInicio: DateTime.tryParse(json['fecha_inicio']?.toString() ?? '') ?? DateTime.now(),
      fechaFin: DateTime.tryParse(json['fecha_fin']?.toString() ?? ''),
      descripcionDetalle: json['descripcion_detalle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viaje_id': viajeId,
      'tipo_incidencia_id': tipoIncidenciaId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'descripcion_detalle': descripcionDetalle,
    };
  }
}
