import 'seed_database.dart';

class ViajeSeeder {
  static const fecha = '2030-01-01';
  static const horaSalida = '08:00:00';

  static Future<int> run(
    SeedDatabase database, {
    required int rutaId,
    required int busId,
  }) => database.ensureRecord(
    table: 'viajes',
    identity: {
      'ruta_id': rutaId,
      'bus_id': busId,
      'fecha_viaje': fecha,
      'hora_salida': horaSalida,
    },
    values: {
      'ruta_id': rutaId,
      'bus_id': busId,
      'fecha_viaje': fecha,
      'hora_salida': horaSalida,
      'estado': 'programado',
      'estado_base': 1,
    },
  );
}
