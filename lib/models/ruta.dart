class Ruta {
  final int? id;
  final String origen;
  final String destino;
  final double? distanciaKm;
  final double precioBase;

  Ruta({
    this.id,
    required this.origen,
    required this.destino,
    this.distanciaKm,
    required this.precioBase,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['id'] as int?,
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      distanciaKm: json['distancia_km'] != null 
          ? double.tryParse(json['distancia_km'].toString()) 
          : null,
      precioBase: double.tryParse(json['precio_base'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origen': origen,
      'destino': destino,
      'distancia_km': distanciaKm,
      'precio_base': precioBase,
    };
  }
}
