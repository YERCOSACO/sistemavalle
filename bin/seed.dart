import 'dart:io';

import 'package:sistemavalle_api/database/database.dart';
import 'package:sistemavalle_api/seeders/database_seeder.dart';
import 'package:sistemavalle_api/seeders/seed_database.dart';
import 'package:sistemavalle_api/utils/config.dart';

Future<void> main(List<String> arguments) async {
  final environment = ApiConfig.loadEnvironment();
  if (environment['APP_ENV'] != 'local' &&
      environment['APP_ENV'] != 'testing') {
    stderr.writeln('Seeder bloqueado: APP_ENV debe ser local o testing.');
    exitCode = 64;
    return;
  }
  if (environment['SEED_DEVELOPMENT_DATA'] != 'true' ||
      !arguments.contains('--confirm-development')) {
    stderr.writeln(
      'Para insertar datos de prueba configura SEED_DEVELOPMENT_DATA=true '
      'y ejecuta con --confirm-development.',
    );
    exitCode = 64;
    return;
  }

  final demoPassword = environment['DEMO_SEED_PASSWORD'];
  if (demoPassword == null || demoPassword.length < 12) {
    stderr.writeln(
      'Configura DEMO_SEED_PASSWORD con al menos 12 caracteres para sembrar '
      'cuentas de desarrollo.',
    );
    exitCode = 64;
    return;
  }

  final host = environment['DB_HOST']?.trim();
  final port = int.tryParse(environment['DB_PORT'] ?? '3306');
  final user = (environment['DB_USER'] ?? environment['DB_USERNAME'])?.trim();
  final database =
      (environment['DB_NAME'] ?? environment['DB_DATABASE'])?.trim();
  if (host == null ||
      host.isEmpty ||
      port == null ||
      port < 1 ||
      port > 65535 ||
      user == null ||
      user.isEmpty ||
      database == null ||
      database.isEmpty) {
    stderr.writeln(
      'Configura DB_HOST, DB_PORT, DB_USERNAME y DB_DATABASE antes de sembrar.',
    );
    exitCode = 64;
    return;
  }

  final connection = await openDatabaseConnection(
    DatabaseConfig(
      host: host,
      port: port,
      user: user,
      password: environment['DB_PASSWORD'] ?? '',
      database: database,
    ),
  );
  try {
    await DatabaseSeeder.run(
      SeedDatabase(connection),
      demoPassword: demoPassword,
    );
    stdout.writeln('Seeders de desarrollo completados correctamente.');
  } catch (error, stackTrace) {
    stderr.writeln('Error al ejecutar los seeders: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    await connection.close();
  }
}
