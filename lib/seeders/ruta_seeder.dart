import 'seed_database.dart';

class RutaSeeder {
  static const precioBaseDemo = 25.0;

  static Future<int> run(SeedDatabase database) => database.ensureRecord(
    table: 'rutas',
    identity: const {'origen': 'Valle Demo', 'destino': 'Destino Demo'},
    values: const {
      'origen': 'Valle Demo',
      'destino': 'Destino Demo',
      'distancia_km': 120.00,
      'precio_base': precioBaseDemo,
      'estado_base': 1,
    },
  );
}
