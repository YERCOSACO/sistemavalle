import 'dart:collection';

import 'package:mysql_client/mysql_client.dart';

class MobileDbConnection {
  MobileDbConnection(this._connection);

  final MySQLConnection _connection;

  Future<MobileDbResult> query(
    String sql, [
    List<Object?> values = const [],
  ]) async {
    final placeholders = RegExp(r'\?').allMatches(sql).length;
    if (placeholders != values.length) {
      throw StateError(
        'Mobile API SQL placeholder count does not match its parameters.',
      );
    }

    var parameterIndex = 0;
    final namedSql = sql.replaceAllMapped(
      RegExp(r'\?'),
      (_) => ':p${parameterIndex++}',
    );
    final parameters = <String, dynamic>{
      for (var index = 0; index < values.length; index++)
        'p$index': values[index],
    };
    final result = await _connection.execute(
      namedSql,
      parameters.isEmpty ? null : parameters,
    );
    return MobileDbResult(
      result.rows.map((row) => Map<String, Object?>.from(row.assoc())).toList(),
      result.lastInsertID,
    );
  }

  Future<T> transaction<T>(
    Future<T> Function(MobileDbConnection transaction) action,
  ) {
    return _connection.transactional(
      (transaction) => action(MobileDbConnection(transaction)),
    );
  }
}

class MobileDbResult extends ListBase<Map<String, Object?>> {
  MobileDbResult(this._rows, BigInt lastInsertId)
    : insertId = lastInsertId > BigInt.zero ? lastInsertId.toInt() : null;

  final List<Map<String, Object?>> _rows;
  final int? insertId;

  @override
  int get length => _rows.length;

  @override
  set length(int value) =>
      throw UnsupportedError('Database result is read-only.');

  @override
  Map<String, Object?> operator [](int index) => _rows[index];

  @override
  void operator []=(int index, Map<String, Object?> value) =>
      throw UnsupportedError('Database result is read-only.');
}
