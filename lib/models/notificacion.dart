class Notificacion {
  final int? id;
  final int clienteId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String canal;
  final String prioridad;
  final DateTime? fechaEnvio;
  final DateTime? fechaLectura;
  final String? estado;

  Notificacion({
    this.id,
    required this.clienteId,
    required this.titulo,
    required this.mensaje,
    this.tipo = 'info',
    this.canal = 'sistema',
    this.prioridad = 'normal',
    this.fechaEnvio,
    this.fechaLectura,
    this.estado = 'pendiente',
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as int?,
      clienteId: json['cliente_id'] as int? ?? 0,
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'info',
      canal: json['canal']?.toString() ?? 'sistema',
      prioridad: json['prioridad']?.toString() ?? 'normal',
      fechaEnvio: DateTime.tryParse(json['fecha_envio']?.toString() ?? ''),
      fechaLectura: DateTime.tryParse(json['fecha_lectura']?.toString() ?? ''),
      estado: json['estado']?.toString() ?? 'pendiente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'canal': canal,
      'prioridad': prioridad,
      'fecha_envio': fechaEnvio?.toIso8601String(),
      'fecha_lectura': fechaLectura?.toIso8601String(),
      'estado': estado,
    };
  }
}
