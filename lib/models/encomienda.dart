import 'tipo_encomienda.dart';
import 'viaje.dart';

class Encomienda {
  final int? id;
  final int? clienteId;
  final String? remitenteNombre;
  final String? remitenteCi;
  final String? remitenteTelefono;
  final String destinatarioNombre;
  final String? destinatarioCi;
  final String? destinatarioTelefono;
  final int viajeId;
  final int tipoEncomiendaId;
  final int cantidad;
  final double totalPagar;
  final String estado;
  final Viaje? viaje;
  final TipoEncomienda? tipoEncomienda;

  Encomienda({
    this.id,
    this.clienteId,
    this.remitenteNombre,
    this.remitenteCi,
    this.remitenteTelefono,
    required this.destinatarioNombre,
    this.destinatarioCi,
    this.destinatarioTelefono,
    required this.viajeId,
    required this.tipoEncomiendaId,
    this.cantidad = 1,
    required this.totalPagar,
    this.estado = 'recibido',
    this.viaje,
    this.tipoEncomienda,
  });

  factory Encomienda.fromJson(Map<String, dynamic> json) {
    return Encomienda(
      id: json['id'] as int?,
      clienteId: json['cliente_id'] as int?,
      remitenteNombre: json['remitente_nombre']?.toString(),
      remitenteCi: json['remitente_ci']?.toString(),
      remitenteTelefono: json['remitente_telefono']?.toString(),
      destinatarioNombre: json['destinatario_nombre']?.toString() ?? '',
      destinatarioCi: json['destinatario_ci']?.toString(),
      destinatarioTelefono: json['destinatario_telefono']?.toString(),
      viajeId: json['viaje_id'] as int? ?? 0,
      tipoEncomiendaId: json['tipo_encomienda_id'] as int? ?? 0,
      cantidad: json['cantidad'] as int? ?? 1,
      totalPagar: double.tryParse(json['total_pagar'].toString()) ?? 0.0,
      estado: json['estado']?.toString() ?? 'recibido',
      viaje: json['viaje'] != null ? Viaje.fromJson(json['viaje']) : null,
      tipoEncomienda: json['tipo_encomienda'] != null ? TipoEncomienda.fromJson(json['tipo_encomienda']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'remitente_nombre': remitenteNombre,
      'remitente_ci': remitenteCi,
      'remitente_telefono': remitenteTelefono,
      'destinatario_nombre': destinatarioNombre,
      'destinatario_ci': destinatarioCi,
      'destinatario_telefono': destinatarioTelefono,
      'viaje_id': viajeId,
      'tipo_encomienda_id': tipoEncomiendaId,
      'cantidad': cantidad,
      'total_pagar': totalPagar,
      'estado': estado,
    };
  }
}
