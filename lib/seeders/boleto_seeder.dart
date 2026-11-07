import 'seed_database.dart';

class BoletoSeeder {
  static const numeroAsiento = '1';
  static const ciPasajero = 'DEMO-PASAJERO-001';

  static Future<void> run(
    SeedDatabase database, {
    required int reservaId,
    required int clienteId,
    required int viajeId,
    required double precio,
  }) {
    return database.transaction((transaction) async {
      final seatRows = await transaction.query(
        'SELECT estado FROM asiento_viajes '
        'WHERE viaje_id = :viaje_id AND numero_asiento = :numero_asiento '
        'AND estado_base = 1 FOR UPDATE',
        {'viaje_id': viajeId, 'numero_asiento': numeroAsiento},
      );
      if (seatRows.isEmpty) {
        throw StateError(
          'No existe el asiento de prueba $numeroAsiento para el viaje $viajeId.',
        );
      }

      final existingTickets = await transaction.query(
        'SELECT reserva_id, ci_pasajero, estado_base FROM boletos '
        'WHERE viaje_id = :viaje_id AND numero_asiento = :numero_asiento '
        'LIMIT 1',
        {'viaje_id': viajeId, 'numero_asiento': numeroAsiento},
      );
      if (existingTickets.isNotEmpty) {
        final ticket = existingTickets.first;
        final isDemoTicket =
            transaction.asInt(ticket['reserva_id']) == reservaId &&
            ticket['ci_pasajero'] == ciPasajero;
        if (!isDemoTicket) {
          throw StateError(
            'El asiento $numeroAsiento del viaje $viajeId ya está registrado; el seeder no lo sobrescribirá.',
          );
        }
        if (ticket['estado_base'] == 1 &&
            seatRows.first['estado'] != 'ocupado') {
          await _markSeatOccupied(transaction, viajeId);
        }
        return;
      }

      if (seatRows.first['estado'] != 'disponible') {
        throw StateError(
          'El asiento de prueba $numeroAsiento del viaje $viajeId no está disponible.',
        );
      }

      await transaction.ensureRecord(
        table: 'boletos',
        identity: {'viaje_id': viajeId, 'numero_asiento': numeroAsiento},
        values: {
          'reserva_id': reservaId,
          'viaje_id': viajeId,
          'numero_asiento': numeroAsiento,
          'nombre_pasajero': 'Pasajero Demo',
          'ci_pasajero': ciPasajero,
          'telefono_pasajero': '0000000000',
          'precio': precio,
          'metodo_pago': 'efectivo',
          'estado': 'confirmado',
          'fecha_emision': '2030-01-01 07:00:00',
          'cliente_emisor_id': clienteId,
          'espacio_extra': 0,
          'mascota': 0,
          'estado_base': 1,
        },
      );
      await _markSeatOccupied(transaction, viajeId);
    });
  }

  static Future<void> _markSeatOccupied(
    SeedDatabase database,
    int viajeId,
  ) async {
    await database.connection.execute(
      'UPDATE asiento_viajes SET estado = :estado '
      'WHERE viaje_id = :viaje_id AND numero_asiento = :numero_asiento',
      {
        'estado': 'ocupado',
        'viaje_id': viajeId,
        'numero_asiento': numeroAsiento,
      },
    );
  }
}
