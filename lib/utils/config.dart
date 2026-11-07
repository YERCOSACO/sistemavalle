import 'dart:io';

import '../database/database.dart';

class ApiConfig {
  const ApiConfig({
    required this.laravelApiUri,
    required this.host,
    required this.port,
    required this.allowedOrigins,
    this.database,
    this.uploadDirectory = 'storage/mobile-comprobantes',
  });

  final Uri laravelApiUri;
  final String host;
  final int port;
  final Set<String> allowedOrigins;
  final DatabaseConfig? database;
  final String uploadDirectory;

  factory ApiConfig.fromEnvironment(Map<String, String> environment) {
    final rawUpstream =
        environment['LARAVEL_API_URL'] ?? 'http://127.0.0.1:8000/api';
    final upstream = Uri.tryParse(rawUpstream.trim());
    if (upstream == null ||
        !const {'http', 'https'}.contains(upstream.scheme) ||
        upstream.host.isEmpty) {
      throw const FormatException(
        'LARAVEL_API_URL must be a valid HTTP(S) URL',
      );
    }

    final apiUri = upstream.replace(
      path: upstream.path.replaceFirst(RegExp(r'/+$'), ''),
    );

    int parsePort(String key, String fallback, {required int max}) {
      final value = int.tryParse(environment[key] ?? fallback);
      if (value == null || value < 1 || value > max) {
        throw FormatException('$key must be an integer between 1 and $max');
      }
      return value;
    }

    final dbHost = environment['DB_HOST']?.trim();
    final dbPort = environment['DB_PORT']?.trim();
    final dbUser =
        (environment['DB_USER'] ?? environment['DB_USERNAME'])?.trim();
    final dbPassword = environment['DB_PASSWORD'] ?? '';
    final dbName =
        (environment['DB_NAME'] ?? environment['DB_DATABASE'])?.trim();
    final hasDatabaseSettings = [
      dbHost,
      dbPort,
      dbUser,
      dbPassword,
      dbName,
    ].any((value) => value != null && value.isNotEmpty);
    DatabaseConfig? database;
    if (hasDatabaseSettings) {
      final parsedDbPort = int.tryParse(dbPort ?? '3306') ?? 3306;
      database = DatabaseConfig(
        host: dbHost ?? '127.0.0.1',
        port: parsedDbPort,
        user: dbUser ?? 'root',
        password: dbPassword,
        database: dbName ?? 'sistema_valle',
      );
    }

    return ApiConfig(
      laravelApiUri: apiUri,
      host:
          environment['HOST']?.trim().isNotEmpty == true
              ? environment['HOST']!.trim()
              : '0.0.0.0',
      port: parsePort('PORT', '8080', max: 65535),
      allowedOrigins:
          (environment['CORS_ALLOWED_ORIGINS'] ?? '')
              .split(',')
              .map((origin) => origin.trim())
              .where((origin) => origin.isNotEmpty)
              .toSet(),
      database: database,
      uploadDirectory:
          environment['MOBILE_UPLOAD_DIRECTORY']?.trim().isNotEmpty == true
              ? environment['MOBILE_UPLOAD_DIRECTORY']!.trim()
              : 'storage/mobile-comprobantes',
    );
  }

  factory ApiConfig.load() {
    final environment = loadEnvironment();

    if (environment['LARAVEL_API_URL']?.trim().isNotEmpty != true) {
      final appUrl = environment['APP_URL']?.trim();
      if (appUrl?.isNotEmpty == true) {
        final normalizedAppUrl = appUrl!.replaceFirst(RegExp(r'/+$'), '');
        environment['LARAVEL_API_URL'] =
            normalizedAppUrl.endsWith('/api')
                ? normalizedAppUrl
                : '$normalizedAppUrl/api';
      }
    }

    return ApiConfig.fromEnvironment(environment);
  }

  static Map<String, String> loadEnvironment() {
    final processEnvironment = Platform.environment;
    final envFilePath = processEnvironment['LARAVEL_ENV_PATH']?.trim();
    final envFile = _resolveEnvironmentFile(envFilePath);
    final fileEnvironment =
        envFile == null ? <String, String>{} : _readEnvironmentFile(envFile);
    return {...fileEnvironment, ...processEnvironment};
  }

  static File? _resolveEnvironmentFile(String? configuredPath) {
    if (configuredPath?.isNotEmpty == true) {
      final file = File(configuredPath!);
      if (!file.existsSync()) {
        throw FormatException(
          'LARAVEL_ENV_PATH does not point to an existing file: $configuredPath',
        );
      }
      return file;
    }

    final projectEnv = File(
      '${Directory.current.path}${Platform.pathSeparator}.env',
    );
    if (projectEnv.existsSync()) return projectEnv;

    final parentEnv = File(
      '${Directory.current.parent.path}${Platform.pathSeparator}.env',
    );
    if (parentEnv.existsSync()) return parentEnv;

    // Convenience fallback for the default local Laragon installation.
    if (Platform.isWindows) {
      final laragonEnv = File(r'C:\laragon\www\pvalle\.env');
      if (laragonEnv.existsSync()) return laragonEnv;
    }
    return null;
  }

  static Map<String, String> _readEnvironmentFile(File file) {
    final values = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      var line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (line.startsWith('export ')) {
        line = line.substring('export '.length).trimLeft();
      }

      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) continue;

      var value = line.substring(separator + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      } else {
        final comment = value.indexOf(RegExp(r'\s+#'));
        if (comment >= 0) value = value.substring(0, comment).trimRight();
      }
      values[key] = value;
    }
    return values;
  }
}
