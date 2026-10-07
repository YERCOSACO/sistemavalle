class Bus {
  final int? id;
  final String placa;
  final int capacidad;
  final String? modelo;
  final String? tipoBus;

  Bus({
    this.id,
    required this.placa,
    required this.capacidad,
    this.modelo,
    this.tipoBus,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as int?,
      placa: json['placa']?.toString() ?? '',
      capacidad: json['capacidad'] as int? ?? 0,
      modelo: json['modelo']?.toString(),
      tipoBus: json['tipo_bus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placa': placa,
      'capacidad': capacidad,
      'modelo': modelo,
      'tipo_bus': tipoBus,
    };
  }
}
