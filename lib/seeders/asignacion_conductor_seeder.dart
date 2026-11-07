import 'seed_database.dart';

class AsignacionConductorSeeder {
  static Future<int> run(
    SeedDatabase database, {
    required int viajeId,
    required int conductorId,
  }) => database.ensureRecord(
    table: 'asignacion_conductores',
    identity: {'viaje_id': viajeId, 'tipo_asignacion': 'principal'},
    values: {
      'viaje_id': viajeId,
      'conductor_id': conductorId,
      'tipo_asignacion': 'principal',
      'estado_base': 1,
    },
  );
}
