class AppUser {
  final String id;
  final String nombreCompleto;
  final String email;
  final String telefono;
  final String? fotoUrl;
  final String? role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.telefono,
    required this.createdAt,
    required this.updatedAt,
    this.fotoUrl,
    this.role,
  });

  AppUser copyWith({
    String? nombreCompleto,
    String? telefono,
    String? fotoUrl,
    DateTime? updatedAt,
    String? role,
  }) {
    return AppUser(
      id: id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      email: email,
      telefono: telefono ?? this.telefono,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      role: role ?? this.role,
    );
  }
}
