import '../utils/mobile_api_exception.dart';

class Passenger {
  const Passenger({
    required this.seat,
    required this.name,
    required this.ci,
    required this.phone,
    required this.type,
  });

  final String seat;
  final String name;
  final String ci;
  final String phone;
  final String type;

  factory Passenger.fromJson(Map<String, dynamic> json) {
    final seat = json['numero_asiento']?.toString().trim() ?? '';
    final type = json['tipo_pasajero']?.toString() ?? 'normal';
    if (seat.isEmpty || seat.length > 12) {
      throw const MobileApiException(422, 'El número de asiento no es válido.');
    }
    if (!const {'normal', 'comodidad', 'mascota'}.contains(type)) {
      throw const MobileApiException(422, 'El tipo de pasajero no es válido.');
    }
    final name = json['nombre_pasajero']?.toString() ?? '';
    final ci = json['ci_pasajero']?.toString() ?? '';
    final phone = json['telefono_pasajero']?.toString() ?? '';
    if (name.length > 255 || ci.length > 50 || phone.length > 50) {
      throw const MobileApiException(
        422,
        'Los datos del pasajero son demasiado largos.',
      );
    }
    return Passenger(seat: seat, name: name, ci: ci, phone: phone, type: type);
  }
}
