import 'boleto.dart';

class Reserva {
  final int? id;
  final int clienteId;
  final DateTime fechaReserva;
  final int cantidad;
  final double totalPagar;
  final String estado;
  final List<Boleto>? boletos;

  Reserva({
    this.id,
    required this.clienteId,
    required this.fechaReserva,
    required this.cantidad,
    required this.totalPagar,
    required this.estado,
    this.boletos,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as int?,
      clienteId: json['cliente_id'] as int? ?? 0,
      fechaReserva: DateTime.tryParse(json['fecha_reserva']?.toString() ?? '') ?? DateTime.now(),
      cantidad: json['cantidad'] as int? ?? 0,
      totalPagar: double.tryParse(json['total_pagar'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? 'pendiente',
      boletos: json['boletos'] != null
          ? (json['boletos'] as List).map((i) => Boleto.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'fecha_reserva': fechaReserva.toIso8601String(),
      'cantidad': cantidad,
      'total_pagar': totalPagar,
      'estado': estado,
    };
  }
}
