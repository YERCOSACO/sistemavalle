import 'seed_database.dart';

class BusSeeder {
  static const capacidadDemo = 40;

  static Future<int> run(SeedDatabase database) => database.ensureRecord(
    table: 'buses',
    identity: const {'placa': 'DEMO-001'},
    values: const {
      'placa': 'DEMO-001',
      'capacidad': capacidadDemo,
      'modelo': 'Modelo de prueba',
      'tipo_bus': 'interprovincial',
      'estado_base': 1,
    },
  );
}
