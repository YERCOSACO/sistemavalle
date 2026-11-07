import 'package:mysql_client/mysql_client.dart';

class DatabaseConfig {
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
}

Future<MySQLConnection> openDatabaseConnection(
  DatabaseConfig configuration,
) async {
  final connection = await MySQLConnection.createConnection(
    host: configuration.host,
    port: configuration.port,
    userName: configuration.user,
    password: configuration.password,
    databaseName: configuration.database,
    secure: true,
  );
  try {
    await connection.connect(
      timeoutMs: const Duration(seconds: 10).inMilliseconds,
    );
    return connection;
  } catch (_) {
    await connection.close();
    rethrow;
  }
}
