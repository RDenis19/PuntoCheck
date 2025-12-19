class AsignacionesHorarios {
  final String id;
  final String perfilId;
  final String organizacionId;
  final String? plantillaId;
  final DateTime fechaInicio; // DATE
  final DateTime? fechaFin; // DATE
  final DateTime? creadoEn;

  AsignacionesHorarios({
    required this.id,
    required this.perfilId,
    required this.organizacionId,
    this.plantillaId,
    required this.fechaInicio,
    this.fechaFin,
    this.creadoEn,
  });

  factory AsignacionesHorarios.fromJson(Map<String, dynamic> json) {
    return AsignacionesHorarios(
      id: json['id'],
      perfilId: json['perfil_id'],
      organizacionId: json['organizacion_id'],
      plantillaId: json['plantilla_id'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'perfil_id': perfilId,
    'organizacion_id': organizacionId,
    'plantilla_id': plantillaId,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'fecha_fin': fechaFin?.toIso8601String(),
  };
}
