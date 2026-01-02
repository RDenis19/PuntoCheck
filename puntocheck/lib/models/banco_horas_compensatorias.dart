class BancoHorasCompensatorias {
  final String id;
  final String organizacionId;
  final String empleadoId;
  final double cantidadHoras; // NUMERIC
  final String concepto; // TEXT
  final String? aprobadoPorId;
  final bool? aceptaRenunciaPago;
  final DateTime? creadoEn;

  final String? empleadoNombres;
  final String? empleadoApellidos;
  final String? empleadoCedula;

  BancoHorasCompensatorias({
    required this.id,
    required this.organizacionId,
    required this.empleadoId,
    required this.cantidadHoras,
    required this.concepto,
    this.aprobadoPorId,
    this.aceptaRenunciaPago,
    this.creadoEn,
    this.empleadoNombres,
    this.empleadoApellidos,
    this.empleadoCedula,
  });

  String get empleadoNombreCompleto {
    final n = (empleadoNombres ?? '').trim();
    final a = (empleadoApellidos ?? '').trim();
    final full = '$n $a'.trim();
    return full.isNotEmpty ? full : 'ID: ${empleadoId.substring(0, 8)}';
  }

  factory BancoHorasCompensatorias.fromJson(Map<String, dynamic> json) {
    String? nombres;
    String? apellidos;
    String? cedula;

    if (json['empleado'] != null && json['empleado'] is Map) {
      final m = Map<String, dynamic>.from(json['empleado']);
      nombres = m['nombres']?.toString();
      apellidos = m['apellidos']?.toString();
      cedula = m['cedula']?.toString();
    }

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
      empleadoNombres: nombres,
      empleadoApellidos: apellidos,
      empleadoCedula: cedula,
    );
  }
}
