class MobileIdentity {
  const MobileIdentity({
    required this.id,
    required this.accountType,
    required this.user,
    this.permissions = const [],
    this.roles = const [],
  });

  final int id;
  final String accountType;
  final Map<String, Object?> user;
  final List<String> permissions;
  final List<String> roles;
}
