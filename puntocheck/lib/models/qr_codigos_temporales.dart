class QrCodigosTemporales {
  final String id;
  final String sucursalId;
  final String organizacionId;
  final String tokenHash;
  final DateTime fechaExpiracion;
  final String? creadoPorId;
  final String? usadoPorId;
  final DateTime? fechaUso;
  final bool? esValido;
  final DateTime? creadoEn;

  QrCodigosTemporales({
    required this.id,
    required this.sucursalId,
    required this.organizacionId,
    required this.tokenHash,
    required this.fechaExpiracion,
    this.creadoPorId,
    this.usadoPorId,
    this.fechaUso,
    this.esValido,
    this.creadoEn,
  });

  factory QrCodigosTemporales.fromJson(Map<String, dynamic> json) {
    return QrCodigosTemporales(
      id: json['id'],
      sucursalId: json['sucursal_id'],
      organizacionId: json['organizacion_id'],
      tokenHash: json['token_hash'],
      fechaExpiracion: DateTime.parse(json['fecha_expiracion']),
      creadoPorId: json['creado_por_id'],
      usadoPorId: json['usado_por_id'],
      fechaUso: json['fecha_uso'] != null
          ? DateTime.parse(json['fecha_uso'])
          : null,
      esValido: json['es_valido'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }
}
