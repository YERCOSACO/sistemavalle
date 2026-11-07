import 'seed_database.dart';

class IncidenciaViajeSeeder {
  static Future<int> run(
    SeedDatabase database, {
    required int viajeId,
    required int tipoIncidenciaId,
  }) async {
    const description = 'Incidencia de prueba local Sistema Valle';
    final existing = await database.query(
      'SELECT id FROM incidencia_viajes '
      'WHERE viaje_id = :viaje_id AND descripcion_detalle = :descripcion '
      'LIMIT 1',
      {'viaje_id': viajeId, 'descripcion': description},
    );
    if (existing.isNotEmpty) return database.asInt(existing.first['id']);

    return database.ensureRecord(
      table: 'incidencia_viajes',
      identity: {'viaje_id': viajeId, 'descripcion_detalle': description},
      values: {
        'viaje_id': viajeId,
        'tipo_incidencia_id': tipoIncidenciaId,
        'fecha_inicio': '2030-01-01 08:30:00',
        'descripcion_detalle': description,
        'estado_base': 1,
      },
    );
  }
}
