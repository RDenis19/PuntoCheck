class AuditoriaLog {
  final String id;
  final String? organizacionId;
  final String? usuarioResponsableId;
  final String accion;
  final String? tablaAfectada;
  final String? idRegistroAfectado;
  final Map<String, dynamic>? detalleCambio; // JSONB
  final String? ipOrigen;
  final String? userAgent;
  final DateTime? creadoEn;

  AuditoriaLog({
    required this.id,
    this.organizacionId,
    this.usuarioResponsableId,
    required this.accion,
    this.tablaAfectada,
    this.idRegistroAfectado,
    this.detalleCambio,
    this.ipOrigen,
    this.userAgent,
    this.creadoEn,
  });

  factory AuditoriaLog.fromJson(Map<String, dynamic> json) {
    return AuditoriaLog(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      usuarioResponsableId: json['usuario_responsable_id'],
      accion: json['accion'],
      tablaAfectada: json['tabla_afectada'],
      idRegistroAfectado: json['id_registro_afectado'],
      detalleCambio: json['detalle_cambio'],
      ipOrigen: json['ip_origen'],
      userAgent: json['user_agent'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }
}
