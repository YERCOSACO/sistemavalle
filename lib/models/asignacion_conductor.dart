class AsignacionConductor {
  final int? id;
  final int viajeId;
  final int conductorId;
  final String tipoAsignacion; // Principal o Relevo

  AsignacionConductor({
    this.id,
    required this.viajeId,
    required this.conductorId,
    required this.tipoAsignacion,
  });

  factory AsignacionConductor.fromJson(Map<String, dynamic> json) {
    return AsignacionConductor(
      id: json['id'] as int?,
      viajeId: json['viaje_id'] as int? ?? 0,
      conductorId: json['conductor_id'] as int? ?? 0,
      tipoAsignacion: json['tipo_asignacion']?.toString() ?? 'Principal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'viaje_id': viajeId,
      'conductor_id': conductorId,
      'tipo_asignacion': tipoAsignacion,
    };
  }
}
