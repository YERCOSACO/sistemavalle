import 'seed_database.dart';

class TipoIncidenciaSeeder {
  static Future<int> run(SeedDatabase database) => database.ensureRecord(
    table: 'tipo_incidencias',
    identity: const {'nombre': 'Incidencia demo'},
    values: const {
      'nombre': 'Incidencia demo',
      'descripcion': 'Tipo de incidencia de prueba local',
      'nivel_gravedad': 'baja',
      'estado_base': 1,
    },
  );
}
