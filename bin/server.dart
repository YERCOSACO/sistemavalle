import 'dart:io';

import 'package:sistemavalle_api/server.dart';

Future<void> main() async {
  try {
    await runServer();
  } on FormatException catch (error) {
    stderr.writeln('Configuración inválida: ${error.message}');
    exitCode = 64;
  } catch (e, stackTrace) {
    stderr.writeln('No se pudo iniciar el servidor API.\n$e\n$stackTrace');
    exitCode = 1;
  }
}
