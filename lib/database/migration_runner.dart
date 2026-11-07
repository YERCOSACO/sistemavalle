import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

import 'migration_files.dart';

class MigrationRunner {
  MigrationRunner(this._connection, this._directory);

  final MySQLConnection _connection;
  final Directory _directory;

  Future<List<String>> migrate() async {
    final files = await discoverMigrations(_directory);
    await _connection.execute('''
CREATE TABLE IF NOT EXISTS dart_migrations (
  migration VARCHAR(255) NOT NULL,
  batch INT UNSIGNED NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (migration)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
''');

    final appliedResult = await _connection.execute(
      'SELECT migration FROM dart_migrations',
    );
    final applied =
        appliedResult.rows
            .map((row) => row.assoc()['migration'].toString())
            .toSet();
    final batchResult = await _connection.execute(
      'SELECT COALESCE(MAX(batch), 0) + 1 AS next_batch FROM dart_migrations',
    );
    final batch = int.parse(
      batchResult.rows.first.assoc()['next_batch'].toString(),
    );
    final completed = <String>[];

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (applied.contains(name)) continue;

      final sql = await file.readAsString();
      final statements =
          sql
              .split(';')
              .map((statement) => statement.trim())
              .where((statement) => statement.isNotEmpty)
              .toList();
      if (statements.length != 1) {
        throw FormatException(
          'La migración $name debe contener exactamente una sentencia SQL.',
        );
      }
      await _connection.execute(statements.single);

      await _connection.execute(
        'INSERT INTO dart_migrations (migration, batch) '
        'VALUES (:migration, :batch)',
        {'migration': name, 'batch': batch},
      );
      completed.add(name);
      stdout.writeln('Migración aplicada: $name');
    }

    if (completed.isEmpty) {
      stdout.writeln('La base ya tiene todas las migraciones aplicadas.');
    }
    return completed;
  }
}
