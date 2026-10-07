class TipoEncomienda {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precio;

  TipoEncomienda({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
  });

  factory TipoEncomienda.fromJson(Map<String, dynamic> json) {
    return TipoEncomienda(
      id: json['id'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
    };
  }
}
