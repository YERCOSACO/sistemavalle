import 'seed_database.dart';

class AsientoViajeSeeder {
  static Future<void> run(
    SeedDatabase database, {
    required int viajeId,
    required int capacidad,
  }) async {
    for (var numero = 1; numero <= capacidad; numero++) {
      await database.ensureRecord(
        table: 'asiento_viajes',
        identity: {'viaje_id': viajeId, 'numero_asiento': numero.toString()},
        values: {
          'viaje_id': viajeId,
          'numero_asiento': numero.toString(),
          'estado': 'disponible',
          'estado_base': 1,
        },
      );
    }
  }
}
