class BancoHorasCompensatorias {
  final String id;
  final String organizacionId;
  final String empleadoId;
  final double cantidadHoras; // NUMERIC
  final DateTime fechaOrigen; // DATE
  final String? motivo;
  final String? aprobadoPorId;
  final bool? advertenciaLegalAceptada;
  final DateTime? creadoEn;

  BancoHorasCompensatorias({
    required this.id,
    required this.organizacionId,
    required this.empleadoId,
    required this.cantidadHoras,
    required this.fechaOrigen,
    this.motivo,
    this.aprobadoPorId,
    this.advertenciaLegalAceptada,
    this.creadoEn,
  });

  factory BancoHorasCompensatorias.fromJson(Map<String, dynamic> json) {
    return BancoHorasCompensatorias(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      empleadoId: json['empleado_id'],
      cantidadHoras: (json['cantidad_horas'] as num).toDouble(),
      fechaOrigen: DateTime.parse(json['fecha_origen']),
      motivo: json['motivo'],
      aprobadoPorId: json['aprobado_por_id'],
      advertenciaLegalAceptada: json['advertencia_legal_aceptada'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }
}
