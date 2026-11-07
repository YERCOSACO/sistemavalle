import 'seed_database.dart';

class ReservaSeeder {
  static const fechaReserva = '2030-01-01 07:00:00';

  static Future<int> run(SeedDatabase database, {required int clienteId}) =>
      database.ensureRecord(
        table: 'reservas',
        identity: {'cliente_id': clienteId, 'fecha_reserva': fechaReserva},
        values: {
          'cliente_id': clienteId,
          'fecha_reserva': fechaReserva,
          'cantidad': 1,
          'estado': 'confirmada',
          'estado_base': 1,
        },
      );
}
