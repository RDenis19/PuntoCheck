/// Modelo para notificaciones del sistema
class Notificacion {
  final String id;
  final String organizacionId;
  final String usuarioDestinoId;
  final String? titulo;
  final String? mensaje;
  final String? tipo;
  final bool leido;
  final DateTime? creadoEn;

  Notificacion({
    required this.id,
    required this.organizacionId,
    required this.usuarioDestinoId,
    this.titulo,
    this.mensaje,
    this.tipo,
    this.leido = false,
    this.creadoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      usuarioDestinoId: json['usuario_destino_id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      tipo: json['tipo'],
      leido: json['leido'] ?? false,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizacion_id': organizacionId,
        'usuario_destino_id': usuarioDestinoId,
        'titulo': titulo,
        'mensaje': mensaje,
        'tipo': tipo,
        'leido': leido,
      };
}
