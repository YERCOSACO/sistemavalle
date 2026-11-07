import 'package:bcrypt/bcrypt.dart';

import 'seed_database.dart';

class UsuarioSeeder {
  static const email = 'personal.demo@sistemavalle.test';

  static Future<int> run(
    SeedDatabase database, {
    required String password,
  }) async {
    final roleRows = await database.query(
      'SELECT id FROM roles WHERE name = :name AND guard_name = :guard LIMIT 1',
      {'name': 'Recepcionista', 'guard': 'web'},
    );
    if (roleRows.isEmpty) {
      throw StateError(
        'No existe el rol Recepcionista. Ejecuta primero el seeder de roles/permisos existente en Laravel.',
      );
    }

    final roleId = database.asInt(roleRows.first['id']);
    final userId = await database.ensureRecord(
      table: 'users',
      identity: const {'email': email},
      values: {
        'name': 'Personal Demo',
        'email': email,
        'password': BCrypt.hashpw(password, BCrypt.gensalt()),
        'estado_base': 1,
      },
    );
    const modelType = r'App\Models\User';

    final assignment = await database.query(
      'SELECT role_id FROM model_has_roles '
      'WHERE role_id = :role_id AND model_id = :model_id '
      'AND model_type = :model_type LIMIT 1',
      {'role_id': roleId, 'model_id': userId, 'model_type': modelType},
    );
    if (assignment.isEmpty) {
      await database.connection.execute(
        'INSERT INTO model_has_roles (role_id, model_type, model_id) '
        'VALUES (:role_id, :model_type, :model_id)',
        {'role_id': roleId, 'model_type': modelType, 'model_id': userId},
      );
    }
    return userId;
  }
}
