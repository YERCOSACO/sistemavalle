class TipoIncidencia {
  final int? id;
  final String nombre;
  final String? descripcion;
  final String nivelGravedad;

  TipoIncidencia({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.nivelGravedad,
  });

  factory TipoIncidencia.fromJson(Map<String, dynamic> json) {
    return TipoIncidencia(
      id: json['id'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      nivelGravedad: json['nivel_gravedad']?.toString() ?? 'Leve',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'nivel_gravedad': nivelGravedad,
    };
  }
}
