import 'seed_database.dart';

class NotificacionSeeder {
  static Future<int> run(SeedDatabase database, {required int clienteId}) =>
      database.ensureRecord(
        table: 'notificaciones',
        identity: {'cliente_id': clienteId, 'titulo': 'Notificación de prueba'},
        values: {
          'cliente_id': clienteId,
          'titulo': 'Notificación de prueba',
          'mensaje': 'Este registro fue creado por los seeders locales.',
          'tipo': 'info',
          'canal': 'sistema',
          'prioridad': 'normal',
          'estado': 'pendiente',
          'estado_base': 1,
        },
      );
}
