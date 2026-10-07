class User {
  final int? id;
  final String name;
  final String email;
  final String? password;
  final bool estadoBase;

  User({this.id, required this.name, required this.email, this.password, this.estadoBase = true});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    estadoBase: json['estado_base'] == 1 || json['estado_base'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (password != null) 'password': password,
    'estado_base': estadoBase ? 1 : 0,
  };
}
