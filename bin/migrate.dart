import 'dart:io';

import 'package:mysql_client/mysql_client.dart';
import 'package:sistemavalle_api/database/database.dart';
import 'package:sistemavalle_api/database/migration_runner.dart';
import 'package:sistemavalle_api/utils/config.dart';

Future<void> main(List<String> arguments) async {
  const confirmation = '--confirm-migrations';
  if (arguments.length != 1 || arguments.single != confirmation) {
    stderr.writeln(
      'Para aplicar cambios de esquema ejecuta '
      'dart run bin/migrate.dart $confirmation.',
    );
    exitCode = 64;
    return;
  }

  final environment = ApiConfig.loadEnvironment();
  if (environment['APP_ENV'] != 'local' &&
      environment['APP_ENV'] != 'testing') {
    stderr.writeln('Migraciones bloqueadas: APP_ENV debe ser local o testing.');
    exitCode = 64;
    return;
  }
  if (environment['MIGRATIONS_ENABLED'] != 'true') {
    stderr.writeln(
      'Migraciones bloqueadas: configura MIGRATIONS_ENABLED=true '
      'para habilitarlas explícitamente.',
    );
    exitCode = 64;
    return;
  }

  final laravelDatabase = environment['LARAVEL_DB_DATABASE']?.trim();
  final targetDatabase = environment['MIGRATION_DB_DATABASE']?.trim();
  final apiDatabases =
      [environment['DB_NAME'], environment['DB_DATABASE']]
          .whereType<String>()
          .map((database) => database.trim())
          .where((database) => database.isNotEmpty)
          .toList();
  final host = environment['MIGRATION_DB_HOST']?.trim();
  final port = int.tryParse(environment['MIGRATION_DB_PORT'] ?? '');
  final user = environment['MIGRATION_DB_USER']?.trim();

  if (laravelDatabase == null ||
      laravelDatabase.isEmpty ||
      targetDatabase == null ||
      targetDatabase.isEmpty ||
      apiDatabases.isEmpty ||
      apiDatabases.any(
        (database) => database.toLowerCase() != targetDatabase.toLowerCase(),
      ) ||
      targetDatabase.toLowerCase() == laravelDatabase.toLowerCase()) {
    stderr.writeln(
      'Configura una base Dart independiente: DB_DATABASE/DB_NAME y '
      'MIGRATION_DB_DATABASE deben coincidir y ser diferentes de '
      'LARAVEL_DB_DATABASE.',
    );
    exitCode = 64;
    return;
  }
  if (host == null ||
      host.isEmpty ||
      port == null ||
      port < 1 ||
      port > 65535 ||
      user == null ||
      user.isEmpty) {
    stderr.writeln(
      'Configura MIGRATION_DB_HOST, MIGRATION_DB_PORT y '
      'MIGRATION_DB_USER antes de migrar.',
    );
    exitCode = 64;
    return;
  }

  final migrationsDirectory = Directory(
    '${Directory.current.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}database${Platform.pathSeparator}migrations',
  );
  MySQLConnection? connection;
  try {
    connection = await openDatabaseConnection(
      DatabaseConfig(
        host: host,
        port: port,
        user: user,
        password: environment['MIGRATION_DB_PASSWORD'] ?? '',
        database: targetDatabase,
      ),
    );
    stdout.writeln('Aplicando migraciones a la base Dart: $targetDatabase');
    await MigrationRunner(connection, migrationsDirectory).migrate();
  } catch (error, stackTrace) {
    stderr.writeln('Error al ejecutar las migraciones: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    await connection?.close();
  }
}
