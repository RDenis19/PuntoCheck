class ColaNotificaciones {
  final String id;
  final String organizacionId;
  final String usuarioDestinoId;
  final String titulo;
  final String mensaje;
  final String? tipo;
  final Map<String, dynamic>? metadataJson; // JSONB
  final String? estadoEnvio;
  final int? intentos;
  final String? errorLog;
  final DateTime? programadoPara;
  final DateTime? creadoEn;

  ColaNotificaciones({
    required this.id,
    required this.organizacionId,
    required this.usuarioDestinoId,
    required this.titulo,
    required this.mensaje,
    this.tipo,
    this.metadataJson,
    this.estadoEnvio,
    this.intentos,
    this.errorLog,
    this.programadoPara,
    this.creadoEn,
  });

  factory ColaNotificaciones.fromJson(Map<String, dynamic> json) {
    return ColaNotificaciones(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      usuarioDestinoId: json['usuario_destino_id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      tipo: json['tipo'],
      metadataJson: json['metadata_json'],
      estadoEnvio: json['estado_envio'],
      intentos: json['intentos'],
      errorLog: json['error_log'],
      programadoPara: json['programado_para'] != null
          ? DateTime.parse(json['programado_para'])
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }
}
