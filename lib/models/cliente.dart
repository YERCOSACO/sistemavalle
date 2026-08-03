class Cliente {
  final int? id;
  final String nombre;
  final String apellido;
  final String? email;
  final String? telefono;
  final String ci;
  final String? password;
  final String? passwordConfirmation;
  final bool estado;

  Cliente({
    this.id,
    required this.nombre,
    required this.apellido,
    this.email,
    this.telefono,
    required this.ci,
    this.password,
    this.passwordConfirmation,
    required this.estado,
  });
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      email: json['email']?.toString(),
      telefono: json['telefono']?.toString(),
      ci: json['ci']?.toString() ?? '',
      password: json['password']?.toString(),
      passwordConfirmation: json['password_confirmation']?.toString(),
      estado: json['estado'] == true || json['estado'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'ci': ci,
      'estado': estado ? 1 : 0,
    };

    if (id != null) {
      data['id'] = id;
    }
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
      data['password_confirmation'] = passwordConfirmation ?? password;
    }

    return data;
  }
}
