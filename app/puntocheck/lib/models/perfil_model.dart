import 'package:puntocheck/models/enums.dart';

class PerfilModel {
  final String id;
  final String? organizacionId;
  final String nombres;
  final String apellidos;
  final String? cedula;
  final RolUsuario rol;
  final String? cargo;
  final String? jefeInmediatoId;
  final String? telefono;
  final String? fotoPerfilUrl;
  final bool activo;
  final DateTime creadoEn;

  PerfilModel({
    required this.id,
    this.organizacionId,
    required this.nombres,
    required this.apellidos,
    this.cedula,
    required this.rol,
    this.cargo,
    this.jefeInmediatoId,
    this.telefono,
    this.fotoPerfilUrl,
    required this.activo,
    required this.creadoEn,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: json['id'] as String,
      organizacionId: json['organizacion_id'] as String?,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      cedula: json['cedula'] as String?,
      rol: RolUsuario.fromString(json['rol'] as String),
      cargo: json['cargo'] as String?,
      jefeInmediatoId: json['jefe_inmediato_id'] as String?,
      telefono: json['telefono'] as String?,
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizacion_id': organizacionId,
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
      'rol': rol.toDbString(),
      'cargo': cargo,
      'jefe_inmediato_id': jefeInmediatoId,
      'telefono': telefono,
      'foto_perfil_url': fotoPerfilUrl,
      'activo': activo,
      // 'creado_en' se omite usualmente en updates, Supabase lo maneja
    };
  }

  // Helper para nombre completo
  String get nombreCompleto => '$nombres $apellidos';
}
