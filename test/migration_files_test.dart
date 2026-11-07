import 'dart:io';

import 'package:sistemavalle_api/database/migration_files.dart';
import 'package:test/test.dart';

void main() {
  test('discovers the ordered functional migration SQL files', () async {
    final files = await discoverMigrations(
      Directory(
        'lib${Platform.pathSeparator}database${Platform.pathSeparator}migrations',
      ),
    );
    final names = files.map((file) => file.uri.pathSegments.last).toList();
    final createdTables = <String>{};

    expect(names, hasLength(34));
    expect(names, orderedEquals([...names]..sort()));
    expect(names, contains('2026_06_19_231457_create_clientes_table.sql'));
    expect(
      names,
      contains('2026_10_08_000001_clear_unconfirmed_ticket_metadata.sql'),
    );
    expect(
      names.any(
        (name) => name.contains('create_cache') || name.contains('create_jobs'),
      ),
      isFalse,
    );
    for (final file in files) {
      final sql = await file.readAsString();
      expect(
        sql.split(';').where((statement) => statement.trim().isNotEmpty),
        hasLength(1),
        reason: '${file.path} must contain one SQL statement',
      );
      final createMatch = RegExp(
        r'\bCREATE TABLE\s+([a-z_]+)',
        caseSensitive: false,
      ).firstMatch(sql);
      final alterMatch = RegExp(
        r'\bALTER TABLE\s+([a-z_]+)',
        caseSensitive: false,
      ).firstMatch(sql);
      final updateMatch = RegExp(
        r'\bUPDATE\s+([a-z_]+)',
        caseSensitive: false,
      ).firstMatch(sql);
      final table =
          createMatch?.group(1) ??
          alterMatch?.group(1) ??
          updateMatch?.group(1);
      expect(table, isNotNull, reason: file.path);

      final references = RegExp(
        r'\bREFERENCES\s+([a-z_]+)',
        caseSensitive: false,
      ).allMatches(sql);
      for (final reference in references) {
        expect(
          createdTables,
          contains(reference.group(1)),
          reason: '${file.path} references a table before it is created',
        );
      }

      if (createMatch != null) {
        expect(createdTables.add(table!), isTrue, reason: file.path);
      } else {
        expect(createdTables, contains(table), reason: file.path);
      }
    }
    expect(
      createdTables,
      unorderedEquals({
        'users',
        'password_reset_tokens',
        'sessions',
        'permissions',
        'roles',
        'model_has_permissions',
        'model_has_roles',
        'role_has_permissions',
        'clientes',
        'buses',
        'conductores',
        'rutas',
        'tipo_encomiendas',
        'tipo_incidencias',
        'personal_access_tokens',
        'viajes',
        'asignacion_conductores',
        'incidencia_viajes',
        'encomiendas',
        'notificaciones',
        'asiento_viajes',
        'reservas',
        'boletos',
      }),
    );
  });
}
