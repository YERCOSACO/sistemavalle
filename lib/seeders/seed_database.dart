import 'package:mysql_client/mysql_client.dart';

class SeedDatabase {
  SeedDatabase(this.connection);

  final MySQLConnection connection;

  Future<T> transaction<T>(Future<T> Function(SeedDatabase) action) {
    return connection.transactional(
      (transaction) => action(SeedDatabase(transaction)),
    );
  }

  Future<List<Map<String, Object?>>> query(
    String sql, [
    Map<String, dynamic> parameters = const {},
  ]) async {
    final result = await connection.execute(
      sql,
      parameters.isEmpty ? null : parameters,
    );
    return result.rows
        .map((row) => Map<String, Object?>.from(row.assoc()))
        .toList();
  }

  Future<int> ensureRecord({
    required String table,
    required Map<String, Object?> identity,
    required Map<String, Object?> values,
  }) async {
    _validateIdentifier(table);
    for (final column in [...identity.keys, ...values.keys]) {
      _validateIdentifier(column);
    }
    if (identity.isEmpty || values.isEmpty) {
      throw ArgumentError('Seeder identities and values cannot be empty.');
    }

    final existing = await query(
      'SELECT id FROM $table WHERE ${identity.keys.map((key) => '$key = :$key').join(' AND ')} LIMIT 1',
      identity,
    );
    if (existing.isNotEmpty) return _asInt(existing.first['id']);

    final columns = values.keys.toList();
    final result = await connection.execute(
      'INSERT INTO $table (${columns.join(', ')}) '
      'VALUES (${columns.map((column) => ':$column').join(', ')})',
      values,
    );
    final id = result.lastInsertID.toInt();
    if (id <= 0) {
      throw StateError('MySQL no devolvió el id insertado en $table.');
    }
    return id;
  }

  Future<int?> findId(String table, Map<String, Object?> identity) async {
    final rows = await query(
      'SELECT id FROM $table WHERE ${identity.keys.map((key) => '$key = :$key').join(' AND ')} LIMIT 1',
      identity,
    );
    return rows.isEmpty ? null : _asInt(rows.first['id']);
  }

  int asInt(Object? value) => _asInt(value);

  void _validateIdentifier(String identifier) {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(identifier)) {
      throw ArgumentError.value(identifier, 'identifier', 'Invalid SQL name.');
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw StateError('MySQL devolvió un id inválido.');
    return parsed;
  }
}
