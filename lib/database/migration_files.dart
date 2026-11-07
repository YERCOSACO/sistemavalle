import 'dart:io';

final _migrationNamePattern = RegExp(
  r'^\d{4}_\d{2}_\d{2}_\d{6}_[a-z0-9_]+\.sql$',
);

Future<List<File>> discoverMigrations(Directory directory) async {
  if (!await directory.exists()) {
    throw FileSystemException(
      'No se encontró el directorio de migraciones.',
      directory.path,
    );
  }

  final files =
      await directory
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .where(
            (file) =>
                _migrationNamePattern.hasMatch(file.uri.pathSegments.last),
          )
          .toList();
  files.sort(
    (first, second) =>
        first.uri.pathSegments.last.compareTo(second.uri.pathSegments.last),
  );
  if (files.isEmpty) {
    throw StateError('No se encontraron archivos SQL de migración.');
  }
  return files;
}
