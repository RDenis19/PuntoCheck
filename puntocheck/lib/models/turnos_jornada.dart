class TurnosJornada {
  final String id;
  final String plantillaId;
  final String nombreTurno;
  final String horaInicio;
  final String horaFin;
  final int? orden;
  final bool? esDiaSiguiente;
  final DateTime? creadoEn;

  const TurnosJornada({
    required this.id,
    required this.plantillaId,
    required this.nombreTurno,
    required this.horaInicio,
    required this.horaFin,
    this.orden,
    this.esDiaSiguiente,
    this.creadoEn,
  });

  factory TurnosJornada.fromJson(Map<String, dynamic> json) {
    return TurnosJornada(
      id: json['id'],
      plantillaId: json['plantilla_id'],
      nombreTurno: json['nombre_turno'],
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      orden: json['orden'],
      esDiaSiguiente: json['es_dia_siguiente'],
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plantilla_id': plantillaId,
        'nombre_turno': nombreTurno,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'orden': orden,
        'es_dia_siguiente': esDiaSiguiente,
      };
}
