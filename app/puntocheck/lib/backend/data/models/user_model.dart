import 'package:puntocheck/backend/domain/entities/app_user.dart';

class UserModel extends AppUser {
  UserModel({
    required super.id,
    required super.nombreCompleto,
    required super.email,
    required super.telefono,
    required super.createdAt,
    required super.updatedAt,
    super.fotoUrl,
    super.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    String parseString(dynamic v) => v == null ? '' : v.toString();

    dynamic createdVal = map['createdAt'] ?? map['created_at'] ?? map['created_at_tz'];
    dynamic updatedVal = map['updatedAt'] ?? map['updated_at'] ?? map['updated_at_tz'];

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v.toString());
    }

    return UserModel(
      id: parseString(map['id']),
      nombreCompleto: parseString(map['nombreCompleto'] ?? map['nombre_completo'] ?? map['full_name']),
      email: parseString(map['email']),
      telefono: parseString(map['telefono'] ?? map['phone'] ?? map['telefono']),
      fotoUrl: map['fotoUrl'] ?? map['foto_url'] as String?,
      role: map['role'] as String?,
      createdAt: parseDate(createdVal),
      updatedAt: parseDate(updatedVal),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Use snake_case / DB column names
      'id': id,
      'full_name': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'foto_url': fotoUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromUser(AppUser user) {
    return UserModel(
      id: user.id,
      nombreCompleto: user.nombreCompleto,
      email: user.email,
      telefono: user.telefono,
      fotoUrl: user.fotoUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
