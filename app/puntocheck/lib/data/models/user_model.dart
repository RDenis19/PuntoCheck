import 'package:puntocheck/domain/entities/app_user.dart';

class UserModel extends AppUser {
  UserModel({
    required super.id,
    required super.nombreCompleto,
    required super.email,
    required super.telefono,
    required super.createdAt,
    required super.updatedAt,
    super.fotoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      nombreCompleto: map['nombreCompleto'] as String,
      email: map['email'] as String,
      telefono: map['telefono'] as String,
      fotoUrl: map['fotoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCompleto': nombreCompleto,
      'email': email,
      'telefono': telefono,
      'fotoUrl': fotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
