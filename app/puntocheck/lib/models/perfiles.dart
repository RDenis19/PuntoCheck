import 'enums.dart';

class Perfiles {
  final String id;
  final String? organizacionId;
  final String nombres;
  final String apellidos;
  final String? cedula;
  final String? correo;
  final String? email;
  final RolUsuario? rol;
  final String? cargo;
  final String? jefeInmediatoId;
  final String? telefono;
  final String? fotoPerfilUrl;
  final bool? activo;
  final bool? eliminado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  Perfiles({
    required this.id,
    this.organizacionId,
    required this.nombres,
    required this.apellidos,
    this.cedula,
    this.correo,
    this.email,
    this.rol,
    this.cargo,
    this.jefeInmediatoId,
    this.telefono,
    this.fotoPerfilUrl,
    this.activo,
    this.eliminado,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Perfiles.fromJson(Map<String, dynamic> json) {
    return Perfiles(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      cedula: json['cedula'],
      correo: json['correo'] ?? json['email'],
      email: json['email'] ?? json['correo'],
      rol: json['rol'] != null ? RolUsuario.fromString(json['rol']) : null,
      cargo: json['cargo'],
      jefeInmediatoId: json['jefe_inmediato_id'],
      telefono: json['telefono'],
      fotoPerfilUrl: json['foto_perfil_url'],
      activo: json['activo'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'])
          : null,
    );
  }

  String get nombreCompleto => '$nombres $apellidos';

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizacion_id': organizacionId,
    'nombres': nombres,
    'apellidos': apellidos,
    'cedula': cedula,
    'rol': rol?.value,
    'cargo': cargo,
    'jefe_inmediato_id': jefeInmediatoId,
    'telefono': telefono,
    'foto_perfil_url': fotoPerfilUrl,
    'activo': activo,
    'eliminado': eliminado,
  };
}
