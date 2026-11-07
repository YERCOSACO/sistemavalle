import 'seed_database.dart';

class EncomiendaSeeder {
  static const totalPagarDemo = 5.0;

  static Future<int> run(
    SeedDatabase database, {
    required int clienteId,
    required int viajeId,
    required int tipoEncomiendaId,
  }) => database.ensureRecord(
    table: 'encomiendas',
    identity: {'viaje_id': viajeId, 'destinatario_ci': 'DEMO-DESTINATARIO-001'},
    values: {
      'cliente_id': clienteId,
      'remitente_nombre': 'Cliente Demo',
      'remitente_ci': 'DEMO-CLIENTE-001',
      'remitente_telefono': '0000000000',
      'destinatario_nombre': 'Destinatario Demo',
      'destinatario_ci': 'DEMO-DESTINATARIO-001',
      'destinatario_telefono': '0000000000',
      'viaje_id': viajeId,
      'tipo_encomienda_id': tipoEncomiendaId,
      'cantidad': 1,
      'total_pagar': totalPagarDemo,
      'estado': 'recibido',
      'estado_base': 1,
    },
  );
}
