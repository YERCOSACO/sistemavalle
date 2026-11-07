import 'package:bcrypt/bcrypt.dart';

import 'seed_database.dart';

class ClienteSeeder {
  static const email = 'cliente.demo@sistemavalle.test';

  static Future<int> run(
    SeedDatabase database, {
    required String password,
  }) async {
    final existingId = await database.findId('clientes', {'email': email});
    if (existingId != null) return existingId;

    return database.ensureRecord(
      table: 'clientes',
      identity: const {'email': email},
      values: {
        'nombre': 'Cliente',
        'apellido': 'Demo',
        'cedula': 'DEMO-CLIENTE-001',
        'email': email,
        'contrasena': BCrypt.hashpw(password, BCrypt.gensalt()),
        'telefono': '0000000000',
        'direccion': 'Registro de prueba local',
        'fecha_nacimiento': '1995-01-01',
        'estado_base': 1,
      },
    );
  }
}
