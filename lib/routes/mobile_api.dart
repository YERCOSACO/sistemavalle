import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

import '../database/database.dart';
import '../models/mobile_identity.dart';
import '../models/passenger.dart';
import '../services/laravel_response.dart';
import '../services/mobile_db_connection.dart';
import '../utils/config.dart';
import '../utils/mobile_api_exception.dart';

typedef _MobileDbConnection = MobileDbConnection;
typedef _MobileIdentity = MobileIdentity;
typedef _Passenger = Passenger;
typedef _LaravelResponse = LaravelResponse;
typedef _MobileApiException = MobileApiException;

class MobileApi {
  MobileApi(this._config, this._database, this._httpClient);

  final ApiConfig _config;
  final DatabaseConfig _database;
  final HttpClient _httpClient;
  static const _proofLimit = 5 * 1024 * 1024;
  static const _uploadExtensions = {'jpg', 'jpeg', 'png', 'pdf'};
  static const _tokenAlphabet =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final Map<String, List<DateTime>> _loginAttempts = {};

  Future<Response> health() async {
    try {
      await _withConnection((connection) async {
        await connection.query('SELECT 1');
        return null;
      });
      return _json(200, {
        'success': true,
        'data': {'status': 'ok', 'mobile_api_configured': true, 'mysql': 'ok'},
      });
    } on SocketException {
      return _json(503, {
        'success': false,
        'data': {
          'status': 'degraded',
          'mobile_api_configured': true,
          'mysql': 'unavailable',
        },
        'message': 'No se pudo conectar con la base de datos.',
      });
    } on MySQLException catch (error, stackTrace) {
      stderr.writeln('Mobile API health database failure: $error\n$stackTrace');
      return _json(503, {
        'success': false,
        'data': {
          'status': 'degraded',
          'mobile_api_configured': true,
          'mysql': 'unavailable',
        },
        'message': 'No se pudo conectar con la base de datos.',
      });
    }
  }

  Future<Response> handle(Request request) async {
    try {
      final path =
          request.url.path.startsWith('/')
              ? request.url.path
              : '/${request.url.path}';
      if (path == '/api/auth/login' && request.method == 'POST') {
        return await _login(request);
      }
      if (path == '/api/auth/register' && request.method == 'POST') {
        return await _registerClient(request);
      }
      if (path == '/api/auth/me' && request.method == 'GET') {
        return await _withConnection(
          (connection) async => _json(
            200,
            _success('Perfil obtenido.', await _profile(request, connection)),
          ),
        );
      }
      if (path == '/api/auth/logout' && request.method == 'POST') {
        return await _logout(request);
      }

      final segments = request.url.pathSegments;
      if (segments.length == 4 &&
          segments[0] == 'api' &&
          segments[1] == 'mobile' &&
          segments[2] == 'comprobantes' &&
          request.method == 'GET') {
        return await _readProof(segments[3]);
      }
      if (path.startsWith('/api/mobile/')) {
        return await _mobileRequest(request);
      }
      return _json(404, _failure('Endpoint móvil no encontrado.'));
    } on _MobileApiException catch (error) {
      return _json(error.statusCode, _failure(error.message));
    } on FormatException catch (error) {
      return _json(400, _failure(error.message));
    } on SocketException {
      return _json(503, _failure('No se pudo conectar con la base de datos.'));
    } on MySQLException catch (error, stackTrace) {
      stderr.writeln('Mobile API database failure: $error\n$stackTrace');
      return _json(
        503,
        _failure('El servicio móvil no pudo completar la operación.'),
      );
    } catch (error, stackTrace) {
      stderr.writeln('Mobile API failure: $error\n$stackTrace');
      return _json(500, _failure('Ocurrió un error interno en la API móvil.'));
    }
  }

  Future<Response?> authorizeStaffPermission(
    Request request,
    String permission,
  ) async {
    try {
      await _withConnection((connection) async {
        final identity = await _authenticate(request, connection);
        _requirePermission(identity, permission);
      });
      return null;
    } on _MobileApiException catch (error) {
      return _json(error.statusCode, _failure(error.message));
    } on FormatException catch (error) {
      return _json(400, _failure(error.message));
    } on SocketException {
      return _json(503, _failure('No se pudo conectar con la base de datos.'));
    } on MySQLException catch (error, stackTrace) {
      stderr.writeln(
        'Mobile API authorization database failure: $error\n$stackTrace',
      );
      return _json(
        503,
        _failure('El servicio móvil no pudo completar la operación.'),
      );
    } catch (error, stackTrace) {
      stderr.writeln('Mobile API authorization failure: $error\n$stackTrace');
      return _json(500, _failure('Ocurrió un error interno en la API móvil.'));
    }
  }

  Future<Response> _registerClient(Request request) async {
    final input = await _readJson(request);
    final name = _requiredString(input, 'nombre').trim();
    final surname = _requiredString(input, 'apellido').trim();
    final identityNumber = _requiredString(input, 'cedula').trim();
    final email = _requiredString(input, 'email').trim().toLowerCase();
    final password = _requiredString(input, 'password');
    final passwordConfirmation = _requiredString(
      input,
      'password_confirmation',
    );
    final phoneValue = input['telefono'];
    if (phoneValue != null && phoneValue is! String) {
      throw const _MobileApiException(422, 'El teléfono no es válido.');
    }
    final phone = (phoneValue as String?)?.trim();

    if (name.isEmpty ||
        name.length > 255 ||
        surname.isEmpty ||
        surname.length > 255 ||
        identityNumber.isEmpty ||
        identityNumber.length > 255 ||
        email.length > 255 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw const _MobileApiException(
        422,
        'Revisa el nombre, apellido, cédula y correo electrónico.',
      );
    }
    if (password.length < 8 || utf8.encode(password).length > 72) {
      throw const _MobileApiException(
        422,
        'La contraseña debe tener al menos 8 caracteres y no superar el límite permitido.',
      );
    }
    if (password != passwordConfirmation) {
      throw const _MobileApiException(
        422,
        'La confirmación de contraseña no coincide.',
      );
    }
    if (phone != null && phone.length > 20) {
      throw const _MobileApiException(
        422,
        'El teléfono no puede superar los 20 caracteres.',
      );
    }

    return _withConnection((connection) async {
      final existingStaff = await connection.query(
        'SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1',
        [email],
      );
      if (existingStaff.isNotEmpty) {
        throw const _MobileApiException(
          409,
          'Ese correo ya está registrado en el sistema.',
        );
      }

      final existingClients = await connection.query(
        'SELECT id FROM clientes '
        'WHERE LOWER(email) = ? OR cedula = ? LIMIT 1',
        [email, identityNumber],
      );
      if (existingClients.isNotEmpty) {
        throw const _MobileApiException(
          409,
          'El correo o la cédula ya están registrados.',
        );
      }

      final now = _sqlDate(DateTime.now().toUtc());
      final passwordHash = BCrypt.hashpw(
        password,
        BCrypt.gensalt(prefix: r'$2y', logRounds: 12),
      );
      late final MobileDbResult result;
      try {
        result = await connection.query(
          'INSERT INTO clientes '
          '(nombre, apellido, cedula, email, contrasena, telefono, estado_base, created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)',
          [
            name,
            surname,
            identityNumber,
            email,
            passwordHash,
            phone?.isEmpty == true ? null : phone,
            now,
            now,
          ],
        );
      } on MySQLServerException catch (error) {
        if (error.errorCode == 1062) {
          throw const _MobileApiException(
            409,
            'El correo o la cédula ya están registrados.',
          );
        }
        rethrow;
      }

      if (result.insertId == null) {
        throw const _MobileApiException(
          500,
          'No se pudo crear la cuenta de cliente.',
        );
      }
      return _json(
        201,
        _success('Cuenta creada. Ahora puedes iniciar sesión.', {
          'user': {
            'id': result.insertId,
            'name': '$name $surname',
            'nombre': name,
            'apellido': surname,
            'email': email,
            'telefono': phone?.isEmpty == true ? null : phone,
            'account_type': 'cliente',
          },
        }),
      );
    });
  }

  Future<Response> _login(Request request) async {
    final input = await _readJson(request);
    final email = _requiredString(input, 'email').trim().toLowerCase();
    final password = _requiredString(input, 'password');
    if (email.isEmpty || password.isEmpty || email.length > 255) {
      throw const _MobileApiException(422, 'Correo o contraseña no válidos.');
    }
    _checkLoginLimit(email);

    return _withConnection((connection) async {
      _LaravelResponse? staffResponse;
      Object? staffConnectionError;
      StackTrace? staffConnectionStack;
      try {
        staffResponse = await _laravelRequest(
          'POST',
          '/login',
          body: {'email': email, 'password': password},
        );
      } on SocketException catch (error, stackTrace) {
        staffConnectionError = error;
        staffConnectionStack = stackTrace;
      } on TimeoutException catch (error, stackTrace) {
        staffConnectionError = error;
        staffConnectionStack = stackTrace;
      }

      Map<String, dynamic>? staffData;
      if (staffResponse?.statusCode == 200) {
        final decoded = _decodeObject(staffResponse!.body);
        staffData = extractStaffLoginPayload(decoded);
      } else if (staffResponse != null &&
          staffResponse.statusCode != 401 &&
          staffResponse.statusCode < 500) {
        final decoded = _tryDecodeObject(staffResponse.body);
        throw _MobileApiException(
          staffResponse.statusCode,
          _message(decoded, 'No se pudo validar la cuenta de personal.'),
        );
      }

      if (staffData != null) {
        final token = staffData['token'];
        final user = staffData['user'];
        if (token is! String || user is! Map<String, dynamic>) {
          throw const _MobileApiException(
            502,
            'La API de personal devolvió una respuesta de autenticación inválida.',
          );
        }
        final userId = _asInt(user['id']);
        if (userId == null) {
          throw const _MobileApiException(
            502,
            'La API de personal no devolvió un identificador válido.',
          );
        }

        final matchingClients = await connection.query(
          'SELECT contrasena FROM clientes '
          'WHERE LOWER(email) = ? AND estado_base = 1 LIMIT 1',
          [email],
        );
        final clientPasswordHash =
            matchingClients.isEmpty
                ? null
                : matchingClients.first['contrasena']?.toString();
        if (clientPasswordHash != null &&
            _verifyLaravelPassword(password, clientPasswordHash)) {
          throw const _MobileApiException(
            409,
            'El correo y la contraseña coinciden con más de una cuenta. Solicita que se corrija la cuenta duplicada.',
          );
        }

        final identity = await _staffIdentity(connection, userId);
        _loginAttempts.remove(email);
        return _json(
          200,
          _success('Inicio de sesión correcto.', {
            'token': token,
            'token_type': 'Bearer',
            'account_type': 'staff',
            'user': {
              ...identity.user,
              'permissions': identity.permissions,
              'roles': identity.roles,
            },
          }),
        );
      }

      final clients = await connection.query(
        'SELECT id, nombre, apellido, email, contrasena, cedula, telefono '
        'FROM clientes WHERE LOWER(email) = ? AND estado_base = 1 LIMIT 1',
        [email],
      );
      final client = clients.isEmpty ? null : clients.first;
      final passwordHash = client?['contrasena']?.toString();
      final clientAuthenticated =
          passwordHash != null &&
          _verifyLaravelPassword(password, passwordHash);

      if (staffConnectionError != null && !clientAuthenticated) {
        Error.throwWithStackTrace(staffConnectionError, staffConnectionStack!);
      }
      if (staffResponse != null &&
          staffResponse.statusCode >= 500 &&
          !clientAuthenticated) {
        final decoded = _tryDecodeObject(staffResponse.body);
        throw _MobileApiException(
          staffResponse.statusCode,
          _message(decoded, 'No se pudo validar la cuenta de personal.'),
        );
      }
      if (!clientAuthenticated || client == null) {
        _recordFailedLogin(email);
        throw const _MobileApiException(401, 'Credenciales incorrectas.');
      }
      _loginAttempts.remove(email);

      final token = _randomToken();
      final tokenHash = sha256.convert(utf8.encode(token)).toString();
      final now = DateTime.now().toUtc();
      final expires = now.add(const Duration(days: 30));
      final tokenResult = await connection.query(
        'INSERT INTO personal_access_tokens '
        '(tokenable_type, tokenable_id, name, token, abilities, expires_at, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'App\\Models\\Cliente',
          client['id'],
          'mobile_app',
          tokenHash,
          jsonEncode(['mobile']),
          _sqlDate(expires),
          _sqlDate(now),
          _sqlDate(now),
        ],
      );
      final clientId = _asInt(client['id']);
      if (clientId == null || tokenResult.insertId == null) {
        throw const _MobileApiException(
          500,
          'No se pudo iniciar una sesión móvil para el cliente.',
        );
      }

      return _json(
        200,
        _success('Inicio de sesión correcto.', {
          'token': '${tokenResult.insertId}|$token',
          'token_type': 'Bearer',
          'account_type': 'cliente',
          'user': _clientProfile(client),
        }),
      );
    });
  }

  Future<Response> _logout(Request request) async {
    final authorization = request.headers['authorization'] ?? '';
    final token = _bearer(authorization);
    if (token == null) {
      throw const _MobileApiException(401, 'La sesión no es válida.');
    }
    final clientToken = _clientTokenParts(token);
    if (clientToken == null) {
      final response = await _laravelRequest('POST', '/logout', bearer: token);
      if (response.statusCode != 200) {
        throw _MobileApiException(
          response.statusCode,
          _message(
            _tryDecodeObject(response.body),
            'No se pudo cerrar sesión.',
          ),
        );
      }
      return _json(200, _success('Sesión cerrada.'));
    }

    await _withConnection((connection) async {
      final identity = await _authenticate(request, connection);
      await connection.query(
        'DELETE FROM personal_access_tokens WHERE id = ? AND tokenable_type = ?',
        [
          clientToken.$1,
          identity.accountType == 'cliente'
              ? 'App\\Models\\Cliente'
              : 'App\\Models\\User',
        ],
      );
      return null;
    });
    return _json(200, _success('Sesión cerrada.'));
  }

  Future<Response> _mobileRequest(Request request) async {
    final contentLength = int.tryParse(request.headers['content-length'] ?? '');
    if (contentLength != null && contentLength > _proofLimit + 256 * 1024) {
      throw const _MobileApiException(
        413,
        'El archivo supera el límite de 5 MB.',
      );
    }

    final parts = request.url.pathSegments;
    return _withConnection((connection) async {
      final auth = await _authenticate(request, connection);

      if (parts.length == 3 &&
          parts[2] == 'encomiendas' &&
          request.method == 'GET') {
        if (auth.accountType != 'cliente') {
          throw const _MobileApiException(
            403,
            'Esta consulta está disponible solo para clientes.',
          );
        }
        return _json(
          200,
          _success(
            'Tus encomiendas.',
            await _clientEncomiendas(connection, auth.id),
          ),
        );
      }

      if (parts.length == 3 &&
          parts[2] == 'viajes' &&
          request.method == 'GET') {
        return _json(
          200,
          _success(
            'Viajes disponibles.',
            await _trips(connection, request.url.queryParameters),
          ),
        );
      }
      if (parts.length == 4 &&
          parts[2] == 'asientos-viaje' &&
          parts[3] == 'buses' &&
          request.method == 'GET') {
        _requirePermission(auth, 'asientoviaje.ver');
        return _json(
          200,
          _success(
            'Buses y viajes disponibles para gestionar sus asientos.',
            await _seatBuses(connection),
          ),
        );
      }
      if (parts.length == 6 &&
          parts[2] == 'asientos-viaje' &&
          parts[3] == 'viajes' &&
          parts[5] == 'asientos') {
        _requirePermission(auth, 'asientoviaje.ver');
        final tripId = int.tryParse(parts[4]);
        if (tripId == null) {
          throw const _MobileApiException(400, 'El viaje no es válido.');
        }
        if (request.method == 'GET') {
          return _json(
            200,
            _success('Asientos del viaje.', await _seats(connection, tripId)),
          );
        }
        if (request.method == 'PATCH') {
          _requirePermission(auth, 'asientoviaje.editar');
          return _json(
            200,
            _success(
              'Estado del asiento actualizado.',
              await _updateTripSeat(
                connection,
                tripId,
                await _readJson(request),
              ),
            ),
          );
        }
        if (request.method == 'DELETE') {
          _requirePermission(auth, 'asientoviaje.eliminar');
          return _json(
            200,
            _success(
              'Asiento eliminado.',
              await _deleteTripSeat(connection, tripId, {
                'numero_asiento': request.url.queryParameters['numero_asiento'],
              }),
            ),
          );
        }
      }
      if (parts.length == 5 &&
          parts[2] == 'viajes' &&
          parts[4] == 'asientos' &&
          request.method == 'GET') {
        final tripId = int.tryParse(parts[3]);
        if (tripId == null) {
          throw const _MobileApiException(
            400,
            'El identificador del viaje no es válido.',
          );
        }
        return _json(
          200,
          _success('Asientos del viaje.', await _seats(connection, tripId)),
        );
      }
      if (parts.length == 3 &&
          parts[2] == 'clientes' &&
          request.method == 'GET') {
        _requirePermission(auth, 'clientes.ver');
        _requirePermission(auth, 'reservas.crear');
        final search = request.url.queryParameters['search']?.trim() ?? '';
        final values =
            search.isEmpty ? <Object?>[] : List<Object?>.filled(4, '%$search%');
        final searchClause =
            search.isEmpty
                ? ''
                : 'AND (nombre LIKE ? OR apellido LIKE ? OR cedula LIKE ? OR email LIKE ?)';
        final customers = await connection.query(
          'SELECT id, nombre, apellido, cedula, email FROM clientes '
          'WHERE estado_base = 1 $searchClause ORDER BY nombre, apellido LIMIT 50',
          values,
        );
        return _json(
          200,
          _success('Clientes encontrados.', [
            for (final row in customers)
              {
                'id': _asInt(row['id']),
                'nombre': '${row['nombre']} ${row['apellido']}',
                'apellido': row['apellido'],
                'cedula': row['cedula'],
                'email': row['email'],
              },
          ]),
        );
      }
      if (parts.length == 3 &&
          parts[2] == 'reservas' &&
          request.method == 'GET') {
        if (auth.accountType == 'staff') {
          _requirePermission(auth, 'reservas.ver');
        }
        return _json(
          200,
          _success('Reservas cargadas.', await _reservations(connection, auth)),
        );
      }
      if (parts.length == 3 &&
          parts[2] == 'reservas' &&
          request.method == 'POST') {
        final input = await _readJson(request);
        final result = await _createBooking(connection, auth, input);
        return _json(
          201,
          _success('Reserva registrada correctamente.', result),
        );
      }
      if (parts.length == 4 &&
          parts[2] == 'reservas' &&
          parts[3] == 'venta' &&
          request.method == 'POST') {
        if (auth.accountType != 'staff') {
          throw const _MobileApiException(
            403,
            'Solo personal puede registrar ventas.',
          );
        }
        final input = await _readJson(request);
        final result = await _createBooking(connection, auth, input);
        return _json(201, _success('Venta registrada correctamente.', result));
      }
      if (parts.length == 5 &&
          parts[2] == 'reservas' &&
          parts[4] == 'comprobante' &&
          request.method == 'POST') {
        final reservationId = int.tryParse(parts[3]);
        if (reservationId == null) {
          throw const _MobileApiException(400, 'La reserva no es válida.');
        }
        return _json(
          200,
          _success(
            'Comprobante recibido.',
            await _uploadProof(request, connection, auth, reservationId),
          ),
        );
      }
      if (parts.length == 5 &&
          parts[2] == 'boletos' &&
          parts[4] == 'confirmar-pago' &&
          request.method == 'PATCH') {
        if (auth.accountType != 'staff') {
          throw const _MobileApiException(
            403,
            'Solo personal puede confirmar pagos.',
          );
        }
        _requirePermission(auth, 'boletos.editar');
        final ticketId = int.tryParse(parts[3]);
        if (ticketId == null) {
          throw const _MobileApiException(400, 'El boleto no es válido.');
        }
        final input = await _readJson(request);
        final manualWhatsAppVerification =
            input['verificacion_manual'] == true &&
            input['canal_verificacion'] == 'whatsapp';
        return _json(
          200,
          _success(
            'Pago confirmado.',
            await _confirmPayment(
              connection,
              ticketId,
              manualWhatsAppVerification: manualWhatsAppVerification,
            ),
          ),
        );
      }
      if (parts.length == 4 &&
          parts[2] == 'boletos' &&
          request.method == 'PATCH') {
        if (auth.accountType != 'staff') {
          throw const _MobileApiException(
            403,
            'Solo personal puede modificar los datos del pasajero.',
          );
        }
        _requirePermission(auth, 'boletos.editar');
        final ticketId = int.tryParse(parts[3]);
        if (ticketId == null) {
          throw const _MobileApiException(400, 'El boleto no es válido.');
        }
        final input = await _readJson(request);
        return _json(
          200,
          _success(
            'Datos del pasajero actualizados.',
            await _updateTicketPassenger(connection, ticketId, input),
          ),
        );
      }
      throw const _MobileApiException(404, 'Endpoint móvil no encontrado.');
    });
  }

  Future<List<Map<String, Object?>>> _seatBuses(
    _MobileDbConnection connection,
  ) async {
    final rows = await connection.query(
      'SELECT b.id AS bus_id, b.placa, b.modelo, b.tipo_bus, b.capacidad, '
      'v.id AS viaje_id, v.fecha_viaje, v.hora_salida, v.estado AS viaje_estado, '
      'r.id AS ruta_id, r.origen, r.destino, r.precio_base '
      'FROM buses b LEFT JOIN viajes v ON v.bus_id = b.id '
      'AND v.estado_base = 1 AND v.estado = ? AND v.fecha_viaje >= CURRENT_DATE '
      'LEFT JOIN rutas r ON r.id = v.ruta_id AND r.estado_base = 1 '
      'WHERE b.estado_base = 1 '
      'ORDER BY b.placa, v.fecha_viaje, v.hora_salida LIMIT 1000',
      ['programado'],
    );
    final buses = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final busId = _asInt(row['bus_id']);
      if (busId == null) continue;
      final bus =
          buses[busId] ??
          {
            'bus': {
              'id': busId,
              'placa': row['placa']?.toString() ?? '',
              'modelo': row['modelo']?.toString(),
              'tipo_bus': row['tipo_bus']?.toString(),
              'capacidad': _asInt(row['capacidad']) ?? 0,
            },
            'viajes': <Map<String, Object?>>[],
          };
      buses[busId] = bus;

      final tripId = _asInt(row['viaje_id']);
      final routeId = _asInt(row['ruta_id']);
      if (tripId == null || routeId == null) continue;
      (bus['viajes']! as List<Map<String, Object?>>).add({
        'id': tripId,
        'ruta_id': routeId,
        'bus_id': busId,
        'fecha_viaje': row['fecha_viaje'].toString().split(' ').first,
        'hora_salida': row['hora_salida']?.toString() ?? '',
        'estado': row['viaje_estado']?.toString() ?? 'programado',
        'ruta': {
          'id': routeId,
          'origen': row['origen']?.toString() ?? '',
          'destino': row['destino']?.toString() ?? '',
          'precio_base': _asDouble(row['precio_base']),
        },
      });
    }
    return buses.values.toList(growable: false);
  }

  Future<Map<String, Object?>> _updateTripSeat(
    _MobileDbConnection connection,
    int tripId,
    Map<String, dynamic> input,
  ) async {
    final seatNumber = _requiredString(input, 'numero_asiento').trim();
    final status = input['estado']?.toString().trim().toLowerCase() ?? '';
    if (seatNumber.isEmpty || seatNumber.length > 12) {
      throw const _MobileApiException(
        422,
        'El número de asiento no es válido.',
      );
    }
    if (!const {'disponible', 'bloqueado'}.contains(status)) {
      throw const _MobileApiException(
        422,
        'El estado debe ser disponible o bloqueado.',
      );
    }

    return connection.transaction((transaction) async {
      await _lockManageableTrip(transaction, tripId);
      await _lockManageableSeat(transaction, tripId, seatNumber);
      await _ensureSeatHasNoActiveTicket(transaction, tripId, seatNumber);
      await transaction.query(
        'UPDATE asiento_viajes SET estado = ?, updated_at = UTC_TIMESTAMP() '
        'WHERE viaje_id = ? AND numero_asiento = ? AND estado_base = 1',
        [status, tripId, seatNumber],
      );
      return {'numero_asiento': seatNumber, 'estado': status};
    });
  }

  Future<Map<String, Object?>> _deleteTripSeat(
    _MobileDbConnection connection,
    int tripId,
    Map<String, dynamic> input,
  ) async {
    final seatNumber = _requiredString(input, 'numero_asiento').trim();
    if (seatNumber.isEmpty || seatNumber.length > 12) {
      throw const _MobileApiException(
        422,
        'El número de asiento no es válido.',
      );
    }

    return connection.transaction((transaction) async {
      await _lockManageableTrip(transaction, tripId);
      await _lockManageableSeat(transaction, tripId, seatNumber);
      await _ensureSeatHasNoActiveTicket(transaction, tripId, seatNumber);
      await transaction.query(
        'UPDATE asiento_viajes SET estado_base = 0, updated_at = UTC_TIMESTAMP() '
        'WHERE viaje_id = ? AND numero_asiento = ? AND estado_base = 1',
        [tripId, seatNumber],
      );
      return {'numero_asiento': seatNumber};
    });
  }

  Future<void> _lockManageableTrip(
    _MobileDbConnection transaction,
    int tripId,
  ) async {
    final rows = await transaction.query(
      'SELECT id FROM viajes WHERE id = ? AND estado_base = 1 '
      'AND estado = ? AND fecha_viaje >= CURRENT_DATE FOR UPDATE',
      [tripId, 'programado'],
    );
    if (rows.isEmpty) {
      throw const _MobileApiException(
        404,
        'El viaje ya no está disponible para administrar asientos.',
      );
    }
  }

  Future<void> _lockManageableSeat(
    _MobileDbConnection transaction,
    int tripId,
    String seatNumber,
  ) async {
    final rows = await transaction.query(
      'SELECT numero_asiento FROM asiento_viajes WHERE viaje_id = ? '
      'AND numero_asiento = ? AND estado_base = 1 FOR UPDATE',
      [tripId, seatNumber],
    );
    if (rows.isEmpty) {
      throw const _MobileApiException(
        404,
        'El asiento no existe o ya fue eliminado.',
      );
    }
  }

  Future<void> _ensureSeatHasNoActiveTicket(
    _MobileDbConnection transaction,
    int tripId,
    String seatNumber,
  ) async {
    final tickets = await transaction.query(
      'SELECT id FROM boletos WHERE viaje_id = ? AND numero_asiento = ? '
      'AND estado_base = 1 AND (estado = ? OR (estado = ? '
      'AND (expira_en IS NULL OR expira_en > UTC_TIMESTAMP()))) '
      'LIMIT 1 FOR UPDATE',
      [tripId, seatNumber, 'confirmado', 'pendiente'],
    );
    if (tickets.isNotEmpty) {
      throw const _MobileApiException(
        409,
        'No se puede modificar ni eliminar un asiento con un boleto vigente.',
      );
    }
  }

  Future<Map<String, Object?>> _updateTicketPassenger(
    _MobileDbConnection connection,
    int ticketId,
    Map<String, dynamic> input,
  ) async {
    final name = _requiredString(input, 'nombre_pasajero').trim();
    final ci = _requiredString(input, 'ci_pasajero').trim();
    final phone = _requiredString(input, 'telefono_pasajero').trim();
    if (name.isEmpty ||
        name.length > 255 ||
        ci.length > 50 ||
        phone.length > 50) {
      throw const _MobileApiException(
        422,
        'Verifica el nombre, CI y teléfono del pasajero.',
      );
    }

    return connection.transaction((transaction) async {
      final rows = await transaction.query(
        'SELECT id, estado, espacio_extra, mascota FROM boletos '
        'WHERE id = ? AND estado_base = 1 FOR UPDATE',
        [ticketId],
      );
      if (rows.isEmpty) {
        throw const _MobileApiException(
          404,
          'No se encontró el boleto activo.',
        );
      }
      final ticket = rows.first;
      if (ticket['estado'] != 'pendiente' && ticket['estado'] != 'confirmado') {
        throw const _MobileApiException(
          409,
          'Solo se pueden modificar boletos pendientes o confirmados.',
        );
      }
      if (_asBool(ticket['espacio_extra']) || _asBool(ticket['mascota'])) {
        throw const _MobileApiException(
          409,
          'Este boleto especial no permite editar datos de pasajero.',
        );
      }

      await transaction.query(
        'UPDATE boletos SET nombre_pasajero = ?, ci_pasajero = ?, '
        'telefono_pasajero = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?',
        [name, ci.isEmpty ? null : ci, phone.isEmpty ? null : phone, ticketId],
      );
      return {
        'id': ticketId,
        'nombre_pasajero': name,
        'ci_pasajero': ci.isEmpty ? null : ci,
        'telefono_pasajero': phone.isEmpty ? null : phone,
      };
    });
  }

  Future<Map<String, Object?>> _createBooking(
    _MobileDbConnection connection,
    _MobileIdentity auth,
    Map<String, dynamic> input,
  ) async {
    final tripId = _asInt(input['viaje_id']);
    final rawTickets = input['boletos'];
    final paymentMethod = input['metodo_pago']?.toString() ?? 'QR';
    if (tripId == null ||
        rawTickets is! List ||
        rawTickets.isEmpty ||
        rawTickets.length > 50) {
      throw const _MobileApiException(
        422,
        'Selecciona un viaje y entre 1 y 50 pasajeros.',
      );
    }
    if (!const {'QR', 'efectivo', 'tarjeta'}.contains(paymentMethod)) {
      throw const _MobileApiException(422, 'La forma de pago no es válida.');
    }
    if (auth.accountType == 'cliente' && paymentMethod != 'QR') {
      throw const _MobileApiException(
        422,
        'El cliente móvil debe pagar mediante QR.',
      );
    }
    if (auth.accountType == 'staff') {
      _requirePermission(auth, 'reservas.crear');
    }
    final customerId =
        auth.accountType == 'cliente' ? auth.id : _asInt(input['cliente_id']);
    if (customerId == null) {
      throw const _MobileApiException(
        422,
        'Selecciona un cliente para la venta.',
      );
    }

    final tickets = <_Passenger>[];
    for (final item in rawTickets) {
      if (item is! Map<String, dynamic>) {
        throw const _MobileApiException(
          422,
          'Los datos de los pasajeros no son válidos.',
        );
      }
      tickets.add(_Passenger.fromJson(item));
    }
    final seatNumbers = tickets.map((ticket) => ticket.seat).toList();
    if (seatNumbers.toSet().length != seatNumbers.length) {
      throw const _MobileApiException(
        422,
        'No repitas un asiento en la misma reserva.',
      );
    }

    final booking = await connection.transaction((transaction) async {
      final customerRows = await transaction.query(
        'SELECT id, nombre, apellido, cedula, telefono FROM clientes '
        'WHERE id = ? AND estado_base = 1 LIMIT 1',
        [customerId],
      );
      if (customerRows.isEmpty) {
        throw const _MobileApiException(
          404,
          'El cliente no existe o está inactivo.',
        );
      }
      final customer = customerRows.first;
      final tripRows = await transaction.query(
        'SELECT v.id, v.fecha_viaje, v.estado, v.estado_base, r.precio_base '
        'FROM viajes v JOIN rutas r ON r.id = v.ruta_id '
        'WHERE v.id = ? AND v.estado_base = 1 AND v.estado = ? '
        'AND v.fecha_viaje >= CURRENT_DATE LIMIT 1',
        [tripId, 'programado'],
      );
      if (tripRows.isEmpty) {
        throw const _MobileApiException(404, 'El viaje ya no está disponible.');
      }
      final trip = tripRows.first;
      final rawPrice = trip['precio_base']?.toString();
      final price = _asDouble(trip['precio_base']);

      final placeholders = List.filled(seatNumbers.length, '?').join(',');
      final seatRows = await transaction.query(
        'SELECT numero_asiento, estado FROM asiento_viajes '
        'WHERE viaje_id = ? AND estado_base = 1 AND numero_asiento IN ($placeholders) '
        'ORDER BY numero_asiento FOR UPDATE',
        [tripId, ...seatNumbers],
      );
      final seatsByNumber = {
        for (final row in seatRows) row['numero_asiento'].toString(): row,
      };
      if (seatsByNumber.length != seatNumbers.length) {
        throw const _MobileApiException(
          409,
          'Uno o más asientos no pertenecen a este viaje.',
        );
      }

      final expiredRows = await transaction.query(
        'SELECT id, numero_asiento FROM boletos WHERE viaje_id = ? '
        'AND numero_asiento IN ($placeholders) AND estado_base = 1 '
        'AND estado = ? AND expira_en IS NOT NULL AND expira_en <= UTC_TIMESTAMP() '
        'FOR UPDATE',
        [tripId, ...seatNumbers, 'pendiente'],
      );
      final expiredSeats =
          expiredRows.map((row) => row['numero_asiento'].toString()).toSet();
      if (expiredRows.isNotEmpty) {
        final expiredIds = expiredRows.map((row) => row['id']).toList();
        final idPlaceholders = List.filled(expiredIds.length, '?').join(',');
        await transaction.query(
          'UPDATE boletos SET estado = ?, estado_base = 0, updated_at = UTC_TIMESTAMP() '
          'WHERE id IN ($idPlaceholders)',
          ['cancelado', ...expiredIds],
        );
      }

      final activeRows = await transaction.query(
        'SELECT numero_asiento FROM boletos WHERE viaje_id = ? '
        'AND numero_asiento IN ($placeholders) AND estado_base = 1 '
        'AND (estado = ? OR (estado = ? AND (expira_en IS NULL OR expira_en > UTC_TIMESTAMP())))',
        [tripId, ...seatNumbers, 'confirmado', 'pendiente'],
      );
      final activeSeats =
          activeRows.map((row) => row['numero_asiento'].toString()).toSet();

      for (final seat in seatNumbers) {
        final row = seatsByNumber[seat]!;
        final state = row['estado'].toString();
        if (state == 'bloqueado' || activeSeats.contains(seat)) {
          throw _MobileApiException(
            409,
            'El asiento $seat acaba de ser ocupado o bloqueado.',
          );
        }
        if (state != 'disponible' &&
            !(state == 'ocupado' && expiredSeats.contains(seat))) {
          throw _MobileApiException(
            409,
            'El asiento $seat no está disponible.',
          );
        }
      }

      final now = DateTime.now().toUtc();
      final expiry =
          paymentMethod == 'QR' ? now.add(const Duration(minutes: 15)) : null;
      await transaction.query(
        'UPDATE asiento_viajes SET estado = ?, updated_at = UTC_TIMESTAMP() '
        'WHERE viaje_id = ? AND numero_asiento IN ($placeholders) AND estado_base = 1',
        ['ocupado', tripId, ...seatNumbers],
      );

      final reservationResult = await transaction.query(
        'INSERT INTO reservas '
        '(cliente_id, fecha_reserva, cantidad, estado, estado_base, created_at, updated_at) '
        'VALUES (?, UTC_TIMESTAMP(), ?, ?, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())',
        [
          customerId,
          tickets.length,
          paymentMethod == 'QR' ? 'pendiente' : 'confirmada',
        ],
      );
      final reservationId = reservationResult.insertId;
      if (reservationId == null) {
        throw const _MobileApiException(500, 'No se pudo crear la reserva.');
      }

      final createdTicketIds = <int>[];
      for (final passenger in tickets) {
        final typeName = switch (passenger.type) {
          'comodidad' => 'Comodidad (espacio extra)',
          'mascota' => 'Mascota',
          _ =>
            passenger.name.trim().isEmpty
                ? '${customer['nombre']} ${customer['apellido']}'
                : passenger.name.trim(),
        };
        final ticketResult = await transaction.query(
          'INSERT INTO boletos '
          '(reserva_id, viaje_id, numero_asiento, nombre_pasajero, ci_pasajero, telefono_pasajero, '
          'espacio_extra, mascota, precio, metodo_pago, estado, expira_en, comprobante_path, estado_base, created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())',
          [
            reservationId,
            tripId,
            passenger.seat,
            typeName,
            passenger.type == 'normal'
                ? (passenger.ci.trim().isEmpty
                    ? customer['cedula']
                    : passenger.ci.trim())
                : null,
            passenger.type == 'normal'
                ? (passenger.phone.trim().isEmpty
                    ? customer['telefono']
                    : passenger.phone.trim())
                : null,
            passenger.type == 'comodidad' ? 1 : 0,
            passenger.type == 'mascota' ? 1 : 0,
            rawPrice!,
            paymentMethod,
            paymentMethod == 'QR' ? 'pendiente' : 'confirmado',
            expiry == null ? null : _sqlDate(expiry),
          ],
        );
        final ticketId = ticketResult.insertId;
        if (ticketId == null) {
          throw const _MobileApiException(
            500,
            'No se pudo registrar uno de los boletos.',
          );
        }
        createdTicketIds.add(ticketId);
      }

      return {
        'id': reservationId,
        'viaje_id': tripId,
        'cantidad': tickets.length,
        'total': price * tickets.length,
        'boletos': createdTicketIds,
        'estado': paymentMethod == 'QR' ? 'pendiente' : 'confirmada',
      };
    });

    return booking;
  }

  Future<List<Map<String, Object?>>> _trips(
    _MobileDbConnection connection,
    Map<String, String> filters,
  ) async {
    final origin = filters['origen']?.trim() ?? '';
    final destination = filters['destino']?.trim() ?? '';
    final date = filters['fecha']?.trim() ?? '';
    final conditions = <String>[];
    final values = <Object?>['disponible', 'programado'];
    if (origin.isNotEmpty) {
      conditions.add('r.origen LIKE ?');
      values.add('%$origin%');
    }
    if (destination.isNotEmpty) {
      conditions.add('r.destino LIKE ?');
      values.add('%$destination%');
    }
    if (date.isNotEmpty) {
      if (DateTime.tryParse(date) == null) {
        throw const _MobileApiException(
          422,
          'La fecha de búsqueda no es válida.',
        );
      }
      conditions.add('v.fecha_viaje = ?');
      values.add(date);
    }
    final filterClause =
        conditions.isEmpty ? '' : 'AND ${conditions.join(' AND ')}';
    final rows = await connection.query(
      'SELECT v.id, v.fecha_viaje, v.hora_salida, '
      'r.id AS ruta_id, r.origen, r.destino, r.precio_base, '
      'b.id AS bus_id, b.placa, b.tipo_bus, '
      '(SELECT COUNT(*) FROM asiento_viajes a WHERE a.viaje_id = v.id '
      'AND a.estado_base = 1 AND a.estado = ?) AS asientos_disponibles '
      'FROM viajes v JOIN rutas r ON r.id = v.ruta_id JOIN buses b ON b.id = v.bus_id '
      'WHERE v.estado_base = 1 AND v.estado = ? AND v.fecha_viaje >= CURRENT_DATE '
      '$filterClause '
      'ORDER BY v.fecha_viaje, v.hora_salida LIMIT 100',
      values,
    );
    return [
      for (final row in rows)
        {
          'id': _asInt(row['id']),
          'ruta_id': _asInt(row['ruta_id']),
          'bus_id': _asInt(row['bus_id']),
          'fecha_viaje': row['fecha_viaje'].toString().split(' ').first,
          'hora_salida': row['hora_salida'].toString(),
          'precio_base': _asDouble(row['precio_base']),
          'ruta': {
            'id': _asInt(row['ruta_id']),
            'origen': row['origen']?.toString() ?? '',
            'destino': row['destino']?.toString() ?? '',
            'precio_base': _asDouble(row['precio_base']),
          },
          'bus': {
            'id': _asInt(row['bus_id']),
            'placa': row['placa']?.toString(),
            'tipo_bus': row['tipo_bus']?.toString(),
          },
          'asientos_disponibles': _asInt(row['asientos_disponibles']) ?? 0,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _seats(
    _MobileDbConnection connection,
    int tripId,
  ) async {
    final tripRows = await connection.query(
      'SELECT id FROM viajes WHERE id = ? AND estado_base = 1 '
      'AND estado = ? AND fecha_viaje >= CURRENT_DATE LIMIT 1',
      [tripId, 'programado'],
    );
    if (tripRows.isEmpty) {
      throw const _MobileApiException(404, 'El viaje ya no está disponible.');
    }
    await connection.transaction((transaction) async {
      final seatRows = await transaction.query(
        'SELECT numero_asiento FROM asiento_viajes WHERE viaje_id = ? '
        'AND estado_base = 1 ORDER BY numero_asiento FOR UPDATE',
        [tripId],
      );
      final expiredRows = await transaction.query(
        'SELECT id, numero_asiento FROM boletos WHERE viaje_id = ? AND estado_base = 1 '
        'AND estado = ? AND expira_en IS NOT NULL AND expira_en <= UTC_TIMESTAMP() FOR UPDATE',
        [tripId, 'pendiente'],
      );
      if (expiredRows.isNotEmpty) {
        final ids = expiredRows.map((row) => row['id']).toList();
        final placeholders = List.filled(ids.length, '?').join(',');
        await transaction.query(
          'UPDATE boletos SET estado = ?, estado_base = 0, updated_at = UTC_TIMESTAMP() '
          'WHERE id IN ($placeholders)',
          ['cancelado', ...ids],
        );
      }
      final activeRows = await transaction.query(
        'SELECT numero_asiento FROM boletos WHERE viaje_id = ? AND estado_base = 1 '
        'AND (estado = ? OR (estado = ? AND (expira_en IS NULL OR expira_en > UTC_TIMESTAMP())))',
        [tripId, 'confirmado', 'pendiente'],
      );
      final activeSeats =
          activeRows.map((row) => row['numero_asiento'].toString()).toSet();
      final inventorySeats =
          seatRows.map((row) => row['numero_asiento'].toString()).toSet();
      for (final row in expiredRows) {
        final number = row['numero_asiento'].toString();
        if (inventorySeats.contains(number) && !activeSeats.contains(number)) {
          await transaction.query(
            'UPDATE asiento_viajes SET estado = ?, updated_at = UTC_TIMESTAMP() '
            'WHERE viaje_id = ? AND numero_asiento = ? AND estado = ?',
            ['disponible', tripId, number, 'ocupado'],
          );
        }
      }
      for (final number in activeSeats) {
        await transaction.query(
          'UPDATE asiento_viajes SET estado = ?, updated_at = UTC_TIMESTAMP() '
          'WHERE viaje_id = ? AND numero_asiento = ? AND estado_base = 1 AND estado = ?',
          ['ocupado', tripId, number, 'disponible'],
        );
      }
      return null;
    });

    final rows = await connection.query(
      'SELECT numero_asiento, estado, estado_base FROM asiento_viajes '
      'WHERE viaje_id = ? AND estado_base = 1 ORDER BY numero_asiento',
      [tripId],
    );
    return [
      for (final row in rows)
        {
          'numero_asiento': row['numero_asiento'].toString(),
          'estado': row['estado'].toString(),
          'estado_base': true,
        },
    ];
  }

  Future<List<Map<String, Object?>>> _reservations(
    _MobileDbConnection connection,
    _MobileIdentity auth,
  ) async {
    final filter = auth.accountType == 'cliente' ? 'AND r.cliente_id = ?' : '';
    final values =
        auth.accountType == 'cliente' ? <Object?>[auth.id] : <Object?>[];
    final rows = await connection.query(
      'SELECT r.id AS reserva_id, r.cliente_id, r.fecha_reserva, r.cantidad, r.estado AS reserva_estado, '
      'c.nombre AS cliente_nombre, c.apellido AS cliente_apellido, '
      'v.id AS viaje_id, v.ruta_id, v.bus_id, v.fecha_viaje, v.hora_salida, '
      'rt.origen, rt.destino, bus.placa, bus.tipo_bus, '
      'b.id AS boleto_id, b.numero_asiento, b.nombre_pasajero, b.ci_pasajero, b.telefono_pasajero, '
      'b.espacio_extra, b.mascota, b.precio, b.metodo_pago, b.estado AS boleto_estado, '
      'b.comprobante_path, b.expira_en, b.fecha_emision, '
      'issuer_user.name AS usuario_emisor, '
      'issuer_client.nombre AS cliente_emisor_nombre, '
      'issuer_client.apellido AS cliente_emisor_apellido '
      'FROM reservas r JOIN clientes c ON c.id = r.cliente_id '
      'LEFT JOIN boletos b ON b.reserva_id = r.id AND b.estado_base = 1 '
      'LEFT JOIN viajes v ON v.id = b.viaje_id '
      'LEFT JOIN rutas rt ON rt.id = v.ruta_id '
      'LEFT JOIN buses bus ON bus.id = v.bus_id '
      'LEFT JOIN users issuer_user ON issuer_user.id = b.usuario_id '
      'LEFT JOIN clientes issuer_client ON issuer_client.id = b.cliente_emisor_id '
      'WHERE r.estado_base = 1 $filter ORDER BY r.created_at DESC, b.id LIMIT 1000',
      values,
    );

    final reservations = <int, Map<String, Object?>>{};
    for (final row in rows) {
      final id = _asInt(row['reserva_id']);
      if (id == null) continue;
      final reservation = reservations.putIfAbsent(
        id,
        () => {
          'id': id,
          'fecha_reserva': row['fecha_reserva']?.toString(),
          'cantidad': _asInt(row['cantidad']),
          'estado': row['reserva_estado']?.toString() ?? 'pendiente',
          'cliente_nombre':
              '${row['cliente_nombre'] ?? ''} ${row['cliente_apellido'] ?? ''}'
                  .trim(),
          'boletos': <Map<String, Object?>>[],
          'viaje': {
            'id': _asInt(row['viaje_id']),
            'ruta_id': _asInt(row['ruta_id']),
            'bus_id': _asInt(row['bus_id']),
            'fecha_viaje': row['fecha_viaje']?.toString().split(' ').first,
            'hora_salida': row['hora_salida']?.toString(),
            'ruta': {
              'origen': row['origen']?.toString(),
              'destino': row['destino']?.toString(),
            },
            'bus': {
              'id': _asInt(row['bus_id']),
              'placa': row['placa']?.toString(),
              'tipo_bus': row['tipo_bus']?.toString(),
            },
          },
        },
      );
      final ticketId = _asInt(row['boleto_id']);
      if (ticketId != null) {
        (reservation['boletos'] as List<Map<String, Object?>>).add({
          'id': ticketId,
          'viaje_id': _asInt(row['viaje_id']),
          'numero_asiento': row['numero_asiento']?.toString(),
          'nombre_pasajero': row['nombre_pasajero']?.toString(),
          'ci_pasajero': row['ci_pasajero']?.toString(),
          'telefono_pasajero': row['telefono_pasajero']?.toString(),
          'espacio_extra': _asBool(row['espacio_extra']),
          'mascota': _asBool(row['mascota']),
          'precio': _asDouble(row['precio']),
          'metodo_pago': row['metodo_pago']?.toString(),
          'estado': row['boleto_estado']?.toString(),
          'comprobante_path': row['comprobante_path']?.toString(),
          'expira_en': row['expira_en']?.toString(),
          'fecha_emision': row['fecha_emision']?.toString(),
          'emitido_por':
              row['usuario_emisor']?.toString() ??
              '${row['cliente_emisor_nombre'] ?? ''} '
                      '${row['cliente_emisor_apellido'] ?? ''}'
                  .trim(),
          'viaje': {
            'id': _asInt(row['viaje_id']),
            'ruta_id': _asInt(row['ruta_id']),
            'bus_id': _asInt(row['bus_id']),
            'fecha_viaje': row['fecha_viaje']?.toString().split(' ').first,
            'hora_salida': row['hora_salida']?.toString(),
            'estado': 'programado',
            'ruta': {
              'id': _asInt(row['ruta_id']),
              'origen': row['origen']?.toString() ?? '',
              'destino': row['destino']?.toString() ?? '',
            },
            'bus': {
              'id': _asInt(row['bus_id']),
              'placa': row['placa']?.toString() ?? '',
              'capacidad': 0,
              'tipo_bus': row['tipo_bus']?.toString(),
            },
          },
        });
      }
    }
    return reservations.values.toList();
  }

  Future<List<Map<String, Object?>>> _clientEncomiendas(
    _MobileDbConnection connection,
    int clientId,
  ) async {
    final rows = await connection.query(
      'SELECT e.id, e.cliente_id, e.remitente_nombre, e.remitente_ci, '
      'e.remitente_telefono, e.destinatario_nombre, e.destinatario_ci, '
      'e.destinatario_telefono, e.viaje_id, e.tipo_encomienda_id, '
      'e.cantidad, e.total_pagar, e.estado, e.estado_base, e.created_at, '
      'v.fecha_viaje, v.hora_salida, v.estado AS viaje_estado, v.ruta_id, '
      'r.origen, r.destino, te.nombre AS tipo_nombre, '
      'te.descripcion AS tipo_descripcion, te.precio AS tipo_precio '
      'FROM encomiendas e '
      'LEFT JOIN viajes v ON v.id = e.viaje_id '
      'LEFT JOIN rutas r ON r.id = v.ruta_id '
      'LEFT JOIN tipo_encomiendas te ON te.id = e.tipo_encomienda_id '
      'WHERE e.cliente_id = ? AND e.estado_base = 1 '
      'ORDER BY e.created_at DESC, e.id DESC LIMIT 500',
      [clientId],
    );

    return [
      for (final row in rows)
        {
          'id': _asInt(row['id']),
          'cliente_id': _asInt(row['cliente_id']),
          'remitente_nombre': row['remitente_nombre']?.toString(),
          'remitente_ci': row['remitente_ci']?.toString(),
          'remitente_telefono': row['remitente_telefono']?.toString(),
          'destinatario_nombre': row['destinatario_nombre']?.toString() ?? '',
          'destinatario_ci': row['destinatario_ci']?.toString(),
          'destinatario_telefono': row['destinatario_telefono']?.toString(),
          'viaje_id': _asInt(row['viaje_id']),
          'tipo_encomienda_id': _asInt(row['tipo_encomienda_id']),
          'cantidad': _asInt(row['cantidad']) ?? 1,
          'total_pagar': _asDouble(row['total_pagar']),
          'estado': row['estado']?.toString() ?? 'recibido',
          'estado_base': _asBool(row['estado_base']),
          'created_at': row['created_at']?.toString(),
          'viaje':
              row['fecha_viaje'] == null
                  ? null
                  : {
                    'id': _asInt(row['viaje_id']),
                    'ruta_id': _asInt(row['ruta_id']),
                    'fecha_viaje':
                        row['fecha_viaje'].toString().split(' ').first,
                    'hora_salida': row['hora_salida']?.toString() ?? '',
                    'estado': row['viaje_estado']?.toString() ?? 'programado',
                    'ruta':
                        row['ruta_id'] == null
                            ? null
                            : {
                              'id': _asInt(row['ruta_id']),
                              'origen': row['origen']?.toString() ?? '',
                              'destino': row['destino']?.toString() ?? '',
                            },
                  },
          'tipo_encomienda':
              row['tipo_nombre'] == null
                  ? null
                  : {
                    'id': _asInt(row['tipo_encomienda_id']),
                    'nombre': row['tipo_nombre']?.toString() ?? '',
                    'descripcion': row['tipo_descripcion']?.toString(),
                    'precio': _asDouble(row['tipo_precio']),
                  },
        },
    ];
  }

  Future<Map<String, Object?>> _uploadProof(
    Request request,
    _MobileDbConnection connection,
    _MobileIdentity auth,
    int reservationId,
  ) async {
    if (auth.accountType != 'cliente') {
      throw const _MobileApiException(
        403,
        'Solo el cliente titular puede enviar el comprobante.',
      );
    }
    final form = request.formData();
    if (form == null) {
      throw const _MobileApiException(
        400,
        'Envía el comprobante como archivo multipart.',
      );
    }
    String? filename;
    List<int>? bytes;
    await for (final item in form.formData) {
      if (item.name != 'comprobante') continue;
      filename = item.filename;
      final builder = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in item.part) {
        length += chunk.length;
        if (length > _proofLimit) {
          throw const _MobileApiException(
            413,
            'El comprobante no puede superar 5 MB.',
          );
        }
        builder.add(chunk);
      }
      bytes = builder.takeBytes();
    }
    final originalName = filename;
    final content = bytes;
    if (originalName == null || content == null || content.isEmpty) {
      throw const _MobileApiException(
        422,
        'Selecciona un archivo de comprobante.',
      );
    }
    final extension = originalName.split('.').last.toLowerCase();
    if (!_uploadExtensions.contains(extension)) {
      throw const _MobileApiException(
        422,
        'Solo se permiten archivos JPG, PNG o PDF.',
      );
    }
    final validSignature = switch (extension) {
      'pdf' =>
        content.length >= 5 &&
            ascii.decode(content.take(5).toList(), allowInvalid: true) ==
                '%PDF-',
      'png' =>
        content.length >= 8 &&
            content.take(8).join(',') == '137,80,78,71,13,10,26,10',
      'jpg' || 'jpeg' =>
        content.length >= 3 &&
            content[0] == 0xff &&
            content[1] == 0xd8 &&
            content[2] == 0xff,
      _ => false,
    };
    if (!validSignature) {
      throw const _MobileApiException(
        422,
        'El contenido del archivo no coincide con su extensión.',
      );
    }

    final reservationRows = await connection.query(
      'SELECT id FROM reservas WHERE id = ? AND cliente_id = ? AND estado_base = 1 LIMIT 1',
      [reservationId, auth.id],
    );
    if (reservationRows.isEmpty) {
      throw const _MobileApiException(
        404,
        'No se encontró la reserva del cliente.',
      );
    }
    final pending = await connection.query(
      'SELECT id FROM boletos WHERE reserva_id = ? AND metodo_pago = ? '
      'AND estado = ? AND estado_base = 1 '
      'AND (expira_en IS NULL OR expira_en > UTC_TIMESTAMP())',
      [reservationId, 'QR', 'pendiente'],
    );
    if (pending.isEmpty) {
      throw const _MobileApiException(
        409,
        'La reserva no tiene pagos QR pendientes.',
      );
    }

    final fileId =
        sha256.convert(utf8.encode(_randomToken(length: 64))).toString();
    final safeName = '$fileId.$extension';
    final relativePath = 'mobile-comprobantes/$safeName';
    final directory = Directory(_config.uploadDirectory);
    await directory.create(recursive: true);
    final destination = File(
      '${directory.path}${Platform.pathSeparator}$safeName',
    );
    await destination.writeAsBytes(content, flush: true);
    try {
      await connection.transaction((transaction) async {
        final locked = await transaction.query(
          'SELECT id FROM reservas WHERE id = ? AND cliente_id = ? AND estado_base = 1 FOR UPDATE',
          [reservationId, auth.id],
        );
        if (locked.isEmpty) {
          throw const _MobileApiException(
            404,
            'No se encontró la reserva del cliente.',
          );
        }
        await transaction.query(
          'UPDATE boletos SET comprobante_path = ?, expira_en = NULL, updated_at = UTC_TIMESTAMP() '
          'WHERE reserva_id = ? AND metodo_pago = ? AND estado = ? AND estado_base = 1 '
          'AND (expira_en IS NULL OR expira_en > UTC_TIMESTAMP())',
          [relativePath, reservationId, 'QR', 'pendiente'],
        );
        final pendingStillExists = await transaction.query(
          'SELECT id FROM boletos WHERE reserva_id = ? AND metodo_pago = ? '
          'AND estado = ? AND estado_base = 1 AND comprobante_path = ? LIMIT 1',
          [reservationId, 'QR', 'pendiente', relativePath],
        );
        if (pendingStillExists.isEmpty) {
          throw const _MobileApiException(
            409,
            'El pago pendiente expiró antes de registrar el comprobante.',
          );
        }
        return null;
      });
    } catch (_) {
      await destination.delete();
      rethrow;
    }
    return {'comprobante_path': relativePath};
  }

  Future<Map<String, Object?>> _confirmPayment(
    _MobileDbConnection connection,
    int ticketId, {
    required bool manualWhatsAppVerification,
  }) async {
    return (await connection.transaction((transaction) async {
      final rows = await transaction.query(
        'SELECT id, reserva_id, estado, metodo_pago, comprobante_path, expira_en '
        'FROM boletos WHERE id = ? AND estado_base = 1 FOR UPDATE',
        [ticketId],
      );
      if (rows.isEmpty) {
        throw const _MobileApiException(404, 'No se encontró el boleto.');
      }
      final ticket = rows.first;
      if (ticket['estado'] != 'pendiente') {
        throw const _MobileApiException(
          409,
          'Solo se pueden confirmar boletos pendientes.',
        );
      }
      if (ticket['metodo_pago'] != 'QR') {
        throw const _MobileApiException(
          409,
          'Solo se pueden confirmar boletos pagados mediante QR.',
        );
      }
      if (ticket['comprobante_path'] == null && !manualWhatsAppVerification) {
        throw const _MobileApiException(
          409,
          'Verifica el pago por WhatsApp antes de confirmar el boleto.',
        );
      }
      final expiry = ticket['expira_en'];
      final parsedExpiry =
          expiry is DateTime
              ? expiry.toUtc()
              : DateTime.tryParse(expiry?.toString() ?? '')?.toUtc();
      if (parsedExpiry != null &&
          !parsedExpiry.isAfter(DateTime.now().toUtc())) {
        throw const _MobileApiException(
          409,
          'El boleto expiró y no se puede confirmar.',
        );
      }
      await transaction.query(
        'UPDATE boletos SET estado = ?, expira_en = NULL, updated_at = UTC_TIMESTAMP() WHERE id = ?',
        ['confirmado', ticketId],
      );
      final confirmed = await transaction.query(
        'SELECT COUNT(*) AS total FROM boletos WHERE reserva_id = ? AND estado_base = 1 AND estado = ?',
        [ticket['reserva_id'], 'confirmado'],
      );
      await transaction.query(
        'UPDATE reservas SET estado = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?',
        [
          (_asInt(confirmed.first['total']) ?? 0) > 0
              ? 'confirmada'
              : 'pendiente',
          ticket['reserva_id'],
        ],
      );
      return {'id': ticketId, 'estado': 'confirmado'};
    }));
  }

  Future<Response> _readProof(String filename) async {
    if (!RegExp(r'^[a-f0-9]{64}\.(jpg|jpeg|png|pdf)$').hasMatch(filename)) {
      throw const _MobileApiException(404, 'No se encontró el comprobante.');
    }
    return _withConnection((connection) async {
      final relativePath = 'mobile-comprobantes/$filename';
      final rows = await connection.query(
        'SELECT id FROM boletos WHERE comprobante_path = ? AND estado_base = 1 LIMIT 1',
        [relativePath],
      );
      if (rows.isEmpty) {
        throw const _MobileApiException(404, 'No se encontró el comprobante.');
      }
      final file = File(
        '${_config.uploadDirectory}${Platform.pathSeparator}$filename',
      );
      if (!await file.exists()) {
        throw const _MobileApiException(
          404,
          'El archivo del comprobante ya no está disponible.',
        );
      }
      final contentType = switch (filename.split('.').last) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'application/pdf',
      };
      return Response.ok(
        file.openRead(),
        headers: {
          'content-type': contentType,
          'cache-control': 'private, no-store',
          'x-content-type-options': 'nosniff',
        },
      );
    });
  }

  Future<Map<String, Object?>> _profile(
    Request request,
    _MobileDbConnection connection,
  ) async {
    final identity = await _authenticate(request, connection);
    return {
      'user': identity.user,
      'account_type': identity.accountType,
      'permissions': identity.permissions,
      'roles': identity.roles,
    };
  }

  Future<_MobileIdentity> _authenticate(
    Request request,
    _MobileDbConnection connection,
  ) async {
    final token = _bearer(request.headers['authorization'] ?? '');
    if (token == null) {
      throw const _MobileApiException(401, 'Inicia sesión para continuar.');
    }
    final parts = _clientTokenParts(token);
    if (parts != null) {
      final rows = await connection.query(
        'SELECT t.id, t.token, t.tokenable_id, t.expires_at, c.id AS cliente_id, '
        'c.nombre, c.apellido, c.email, c.cedula, c.telefono '
        'FROM personal_access_tokens t JOIN clientes c ON c.id = t.tokenable_id '
        'WHERE t.id = ? AND t.tokenable_type = ? AND c.estado_base = 1 LIMIT 1',
        [parts.$1, 'App\\Models\\Cliente'],
      );
      if (rows.isEmpty) {
        throw const _MobileApiException(401, 'La sesión del cliente expiró.');
      }
      final row = rows.first;
      final expiry = row['expires_at'];
      final parsedExpiry =
          expiry is DateTime
              ? expiry.toUtc()
              : DateTime.tryParse(expiry?.toString() ?? '')?.toUtc();
      if (!_constantTimeEquals(
            row['token'].toString(),
            sha256.convert(utf8.encode(parts.$2)).toString(),
          ) ||
          (parsedExpiry != null &&
              parsedExpiry.isBefore(DateTime.now().toUtc()))) {
        throw const _MobileApiException(401, 'La sesión del cliente expiró.');
      }
      await connection.query(
        'UPDATE personal_access_tokens SET last_used_at = UTC_TIMESTAMP() WHERE id = ?',
        [parts.$1],
      );
      return _MobileIdentity(
        id: _asInt(row['cliente_id'])!,
        accountType: 'cliente',
        user: _clientProfile(row),
      );
    }

    final response = await _laravelRequest('GET', '/me', bearer: token);
    if (response.statusCode != 200) {
      throw const _MobileApiException(401, 'La sesión del personal expiró.');
    }
    final data = _decodeObject(response.body)['data'];
    final user = data is Map<String, dynamic> ? data['user'] : null;
    final staffId = user is Map<String, dynamic> ? _asInt(user['id']) : null;
    if (staffId == null) {
      throw const _MobileApiException(
        401,
        'La sesión del personal no es válida.',
      );
    }
    return _staffIdentity(connection, staffId);
  }

  Future<_MobileIdentity> _staffIdentity(
    _MobileDbConnection connection,
    int id,
  ) async {
    final user = await _staffProfile(connection, id);
    final permissions = await _staffPermissions(connection, id);
    final rolesRows = await connection.query(
      'SELECT r.name FROM roles r JOIN model_has_roles mhr ON mhr.role_id = r.id '
      'WHERE mhr.model_id = ? AND mhr.model_type = ? ORDER BY r.name',
      [id, 'App\\Models\\User'],
    );
    return _MobileIdentity(
      id: id,
      accountType: 'staff',
      user: user,
      permissions: permissions,
      roles: rolesRows.map((row) => row['name'].toString()).toList(),
    );
  }

  Future<Map<String, Object?>> _staffProfile(
    _MobileDbConnection connection,
    int id,
  ) async {
    final rows = await connection.query(
      'SELECT id, name, email FROM users WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) {
      throw const _MobileApiException(
        401,
        'La cuenta de personal ya no existe.',
      );
    }
    final row = rows.first;
    return {
      'id': _asInt(row['id']),
      'name': row['name']?.toString(),
      'email': row['email']?.toString(),
      'account_type': 'staff',
    };
  }

  Future<List<String>> _staffPermissions(
    _MobileDbConnection connection,
    int id,
  ) async {
    final rows = await connection.query(
      'SELECT DISTINCT p.name FROM permissions p '
      'JOIN role_has_permissions rhp ON rhp.permission_id = p.id '
      'JOIN model_has_roles mhr ON mhr.role_id = rhp.role_id '
      'WHERE mhr.model_id = ? AND mhr.model_type = ? '
      'UNION SELECT DISTINCT p.name FROM permissions p '
      'JOIN model_has_permissions mhp ON mhp.permission_id = p.id '
      'WHERE mhp.model_id = ? AND mhp.model_type = ? ORDER BY name',
      [id, 'App\\Models\\User', id, 'App\\Models\\User'],
    );
    return rows.map((row) => row['name'].toString()).toList();
  }

  void _requirePermission(_MobileIdentity identity, String permission) {
    if (identity.accountType != 'staff' ||
        !identity.permissions.contains(permission)) {
      throw _MobileApiException(403, 'No tienes permiso para $permission.');
    }
  }

  Future<_LaravelResponse> _laravelRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? bearer,
  }) async {
    final uri = _config.laravelApiUri.replace(
      path: '${_config.laravelApiUri.path}$path',
    );
    final request = await _httpClient
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    if (bearer != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    final response = await request.close().timeout(const Duration(seconds: 15));
    return _LaravelResponse(
      response.statusCode,
      await response.transform(utf8.decoder).join(),
    );
  }

  Future<T> _withConnection<T>(
    Future<T> Function(_MobileDbConnection connection) action,
  ) async {
    final connection = await openDatabaseConnection(_database);
    try {
      return await action(_MobileDbConnection(connection));
    } finally {
      await connection.close();
    }
  }

  Future<Map<String, dynamic>> _readJson(Request request) async {
    const maxJsonBytes = 1024 * 1024;
    final contentLength = int.tryParse(request.headers['content-length'] ?? '');
    if (contentLength != null && contentLength > maxJsonBytes) {
      throw const _MobileApiException(
        413,
        'La solicitud supera el límite permitido.',
      );
    }
    final builder = BytesBuilder(copy: false);
    var bytesRead = 0;
    await for (final chunk in request.read()) {
      bytesRead += chunk.length;
      if (bytesRead > maxJsonBytes) {
        throw const _MobileApiException(
          413,
          'La solicitud supera el límite permitido.',
        );
      }
      builder.add(chunk);
    }
    final decoded = jsonDecode(utf8.decode(builder.takeBytes()));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El cuerpo JSON debe ser un objeto.');
    }
    return decoded;
  }

  static Map<String, dynamic>? extractStaffLoginPayload(
    Map<String, dynamic> response,
  ) {
    final candidates = <Map<String, dynamic>>[];
    final data = response['data'];
    if (data is Map) {
      candidates.add(Map<String, dynamic>.from(data));
    }
    if (response.containsKey('token') || response.containsKey('user')) {
      candidates.add(response);
    }

    for (final candidate in candidates) {
      final success = candidate['success'] ?? response['success'];
      final token = candidate['token'] ?? response['token'];
      final user = candidate['user'] ?? response['user'];
      final hasToken = token is String && token.trim().isNotEmpty;
      final hasUser = user is Map;
      if (hasToken && hasUser && success != false) {
        return {'token': token, 'user': Map<String, dynamic>.from(user)};
      }
    }
    return null;
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respuesta JSON no válida.');
    }
    return decoded;
  }

  Map<String, dynamic> _tryDecodeObject(String body) {
    try {
      return _decodeObject(body);
    } on FormatException {
      return const {};
    }
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw _MobileApiException(422, 'El campo $key es obligatorio.');
    }
    return value;
  }

  bool _verifyLaravelPassword(String password, String hash) {
    final compatibleHash =
        hash.startsWith(r'$2y$') ? '\$2a\$${hash.substring(4)}' : hash;
    try {
      return BCrypt.checkpw(password, compatibleHash);
    } on ArgumentError {
      return false;
    }
  }

  void _checkLoginLimit(String email) {
    final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    final attempts =
        _loginAttempts[email]
          ?..removeWhere((attempt) => attempt.isBefore(cutoff));
    if ((attempts?.length ?? 0) >= 5) {
      throw const _MobileApiException(
        429,
        'Demasiados intentos. Espera un minuto y vuelve a intentarlo.',
      );
    }
  }

  void _recordFailedLogin(String email) {
    final now = DateTime.now().toUtc();
    final attempts = _loginAttempts.putIfAbsent(email, () => []);
    attempts.removeWhere(
      (attempt) => attempt.isBefore(now.subtract(const Duration(minutes: 1))),
    );
    attempts.add(now);
    if (_loginAttempts.length > 10000) {
      _loginAttempts.remove(_loginAttempts.keys.first);
    }
  }

  String _randomToken({int length = 48}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _tokenAlphabet[random.nextInt(_tokenAlphabet.length)],
    ).join();
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }

  (int, String)? _clientTokenParts(String token) {
    final separator = token.indexOf('|');
    if (separator <= 0 || separator == token.length - 1) return null;
    final id = int.tryParse(token.substring(0, separator));
    if (id == null) return null;
    return (id, token.substring(separator + 1));
  }

  String? _bearer(String authorization) {
    if (!authorization.startsWith('Bearer ')) return null;
    final token = authorization.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  Map<String, Object?> _clientProfile(dynamic row) => {
    'id': _asInt(row['cliente_id'] ?? row['id']),
    'name': '${row['nombre'] ?? ''} ${row['apellido'] ?? ''}'.trim(),
    'nombre': row['nombre']?.toString(),
    'apellido': row['apellido']?.toString(),
    'email': row['email']?.toString(),
    'cedula': row['cedula']?.toString(),
    'telefono': row['telefono']?.toString(),
    'account_type': 'cliente',
  };

  String _message(Map<String, dynamic> response, String fallback) {
    final message = response['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite) {
      throw const FormatException(
        'Un importe recibido de la base de datos no es válido.',
      );
    }
    return parsed;
  }

  bool _asBool(Object? value) =>
      value == true || value == 1 || value?.toString() == '1';

  String _sqlDate(DateTime value) =>
      value.toIso8601String().substring(0, 19).replaceFirst('T', ' ');

  Map<String, Object?> _success(String message, [Object? data]) => {
    'success': true,
    'message': message,
    'data': data ?? <Object?>[],
  };

  Map<String, Object?> _failure(String message) => {
    'success': false,
    'message': message,
  };

  Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}
