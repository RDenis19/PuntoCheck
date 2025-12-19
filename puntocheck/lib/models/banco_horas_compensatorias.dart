class BancoHorasCompensatorias {
  final String id;
  final String organizacionId;
  final String empleadoId;
  final double cantidadHoras; // NUMERIC
  final String concepto; // TEXT
  final String? aprobadoPorId;
  final bool? aceptaRenunciaPago;
  final DateTime? creadoEn;

  BancoHorasCompensatorias({
    required this.id,
    required this.organizacionId,
    required this.empleadoId,
    required this.cantidadHoras,
    required this.concepto,
    this.aprobadoPorId,
    this.aceptaRenunciaPago,
    this.creadoEn,
  });

  factory BancoHorasCompensatorias.fromJson(Map<String, dynamic> json) {
    return BancoHorasCompensatorias(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      empleadoId: json['empleado_id'],
      cantidadHoras: (json['cantidad_horas'] as num).toDouble(),
      concepto: json['concepto'],
      aprobadoPorId: json['aprobado_por_id'],
      aceptaRenunciaPago: json['acepta_renuncia_pago'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }
}
