import 'asiento_viaje_seeder.dart';
import 'asignacion_conductor_seeder.dart';
import 'bus_seeder.dart';
import 'cliente_seeder.dart';
import 'conductor_seeder.dart';
import 'encomienda_seeder.dart';
import 'incidencia_viaje_seeder.dart';
import 'notificacion_seeder.dart';
import 'boleto_seeder.dart';
import 'reserva_seeder.dart';
import 'ruta_seeder.dart';
import 'seed_database.dart';
import 'tipo_encomienda_seeder.dart';
import 'tipo_incidencia_seeder.dart';
import 'usuario_seeder.dart';
import 'viaje_seeder.dart';

class DatabaseSeeder {
  static Future<void> run(
    SeedDatabase database, {
    required String demoPassword,
  }) async {
    final clienteId = await ClienteSeeder.run(database, password: demoPassword);
    await UsuarioSeeder.run(database, password: demoPassword);
    final busId = await BusSeeder.run(database);
    final conductorId = await ConductorSeeder.run(database);
    final rutaId = await RutaSeeder.run(database);
    final tipoEncomiendaId = await TipoEncomiendaSeeder.run(database);
    final tipoIncidenciaId = await TipoIncidenciaSeeder.run(database);

    final viajeId = await ViajeSeeder.run(
      database,
      rutaId: rutaId,
      busId: busId,
    );
    await AsientoViajeSeeder.run(
      database,
      viajeId: viajeId,
      capacidad: BusSeeder.capacidadDemo,
    );
    await AsignacionConductorSeeder.run(
      database,
      viajeId: viajeId,
      conductorId: conductorId,
    );

    final reservaId = await ReservaSeeder.run(database, clienteId: clienteId);
    await BoletoSeeder.run(
      database,
      reservaId: reservaId,
      clienteId: clienteId,
      viajeId: viajeId,
      precio: RutaSeeder.precioBaseDemo,
    );
    await EncomiendaSeeder.run(
      database,
      clienteId: clienteId,
      viajeId: viajeId,
      tipoEncomiendaId: tipoEncomiendaId,
    );
    await IncidenciaViajeSeeder.run(
      database,
      viajeId: viajeId,
      tipoIncidenciaId: tipoIncidenciaId,
    );
    await NotificacionSeeder.run(database, clienteId: clienteId);
  }
}
