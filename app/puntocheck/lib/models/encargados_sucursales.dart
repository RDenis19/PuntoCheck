import 'perfiles.dart';

class EncargadosSucursales {
  final String id;
  final String sucursalId;
  final String managerId;
  final bool? activo;
  final DateTime? creadoEn;
  final Perfiles? managerProfile;

  const EncargadosSucursales({
    required this.id,
    required this.sucursalId,
    required this.managerId,
    this.activo,
    this.creadoEn,
    this.managerProfile,
  });

  factory EncargadosSucursales.fromJson(Map<String, dynamic> json) {
    return EncargadosSucursales(
      id: json['id'] as String,
      sucursalId: json['sucursal_id'] as String,
      managerId: json['manager_id'] as String,
      activo: json['activo'] as bool?,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
      managerProfile: json['perfiles'] != null
          ? Perfiles.fromJson(Map<String, dynamic>.from(json['perfiles'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sucursal_id': sucursalId,
        'manager_id': managerId,
        'activo': activo,
        'creado_en': creadoEn?.toIso8601String(),
        if (managerProfile != null) 'perfiles': managerProfile!.toJson(),
      };
}
