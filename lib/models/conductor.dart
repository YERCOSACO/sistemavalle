class Conductor {
  final int? id;
  final String nombre;
  final String apellido;
  final String licencia;
  final String? telefono;
  final bool estadoBase;

  Conductor({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.licencia,
    this.telefono,
    this.estadoBase = true,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      licencia: json['licencia']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      estadoBase: json['estado_base'] == 1 || json['estado_base'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'licencia': licencia,
      'telefono': telefono,
      'estado_base': estadoBase ? 1 : 0,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}
