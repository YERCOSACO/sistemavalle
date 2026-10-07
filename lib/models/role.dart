class Role {
  final int? id;
  final String name;
  final String guardName;

  Role({this.id, required this.name, this.guardName = 'web'});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id'],
    name: json['name'] ?? '',
    guardName: json['guard_name'] ?? 'web',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'guard_name': guardName};
}
