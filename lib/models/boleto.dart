class Boleto {
  final int? id;
  final int reservaId;
  final int viajeId;
  final String numeroAsiento;
  final String nombrePasajero;
  final String? ciPasajero;
  final String? telefonoPasajero;
  final double precio;
  final String metodoPago;
  final String estado;
  final DateTime? expiraEn;
  final String? comprobantePath;

  Boleto({
    this.id,
    required this.reservaId,
    required this.viajeId,
    required this.numeroAsiento,
    required this.nombrePasajero,
    this.ciPasajero,
    this.telefonoPasajero,
    required this.precio,
    this.metodoPago = 'QR',
    this.estado = 'pendiente',
    this.expiraEn,
    this.comprobantePath,
  });

  factory Boleto.fromJson(Map<String, dynamic> json) {
    return Boleto(
      id: json['id'] as int?,
      reservaId: json['reserva_id'] as int? ?? 0,
      viajeId: json['viaje_id'] as int? ?? 0,
      numeroAsiento: json['numero_asiento']?.toString() ?? '',
      nombrePasajero: json['nombre_pasajero']?.toString() ?? '',
      ciPasajero: json['ci_pasajero']?.toString(),
      telefonoPasajero: json['telefono_pasajero']?.toString(),
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      metodoPago: json['metodo_pago']?.toString() ?? 'QR',
      estado: json['estado']?.toString() ?? 'pendiente',
      expiraEn: DateTime.tryParse(json['expira_en']?.toString() ?? ''),
      comprobantePath: json['comprobante_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reserva_id': reservaId,
      'viaje_id': viajeId,
      'numero_asiento': numeroAsiento,
      'nombre_pasajero': nombrePasajero,
      'ci_pasajero': ciPasajero,
      'telefono_pasajero': telefonoPasajero,
      'precio': precio,
      'metodo_pago': metodoPago,
      'estado': estado,
      'expira_en': expiraEn?.toIso8601String(),
      'comprobante_path': comprobantePath,
    };
  }
}
