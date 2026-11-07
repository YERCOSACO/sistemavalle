import 'seed_database.dart';

class TipoEncomiendaSeeder {
  static const precioDemo = 5.0;

  static Future<int> run(SeedDatabase database) => database.ensureRecord(
    table: 'tipo_encomiendas',
    identity: const {'nombre': 'Paquete demo'},
    values: const {
      'nombre': 'Paquete demo',
      'descripcion': 'Tipo de encomienda de prueba local',
      'precio': precioDemo,
      'estado_base': 1,
    },
  );
}
