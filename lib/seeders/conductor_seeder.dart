import 'seed_database.dart';

class ConductorSeeder {
  static Future<int> run(SeedDatabase database) => database.ensureRecord(
    table: 'conductores',
    identity: const {'licencia': 'DEMO-LIC-001'},
    values: const {
      'nombre': 'Conductor',
      'apellido': 'Demo',
      'licencia': 'DEMO-LIC-001',
      'telefono': '0000000000',
      'estado_base': 1,
    },
  );
}
