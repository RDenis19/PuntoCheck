import 'enums.dart';

class SolicitudesPermisos {
  final String id;
  final String organizacionId;
  final String solicitanteId;
  final String? solicitanteNombres;
  final String? solicitanteApellidos;
  final TipoPermiso tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int diasTotales;
  final String? motivoDetalle;
  final String? documentoSoporteUrl;
  final EstadoAprobacion? estado;
  final String? aprobadoPorId;
  final DateTime? fechaResolucion;
  final String? comentarioResolucion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  SolicitudesPermisos({
    required this.id,
    required this.organizacionId,
    required this.solicitanteId,
    this.solicitanteNombres,
    this.solicitanteApellidos,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diasTotales,
    this.motivoDetalle,
    this.documentoSoporteUrl,
    this.estado,
    this.aprobadoPorId,
    this.fechaResolucion,
    this.comentarioResolucion,
    this.creadoEn,
    this.actualizadoEn,
  });

  String get solicitanteNombreCompleto {
    final nombres = (solicitanteNombres ?? '').trim();
    final apellidos = (solicitanteApellidos ?? '').trim();
    final full = '$nombres $apellidos'.trim();
    if (full.isNotEmpty) return full;
    return 'ID: ${solicitanteId.substring(0, 8)}';
  }

  factory SolicitudesPermisos.fromJson(Map<String, dynamic> json) {
    String? solicitanteNombres;
    String? solicitanteApellidos;
    final perfil = json['solicitante'] ?? json['perfiles'];
    if (perfil is Map) {
      final map = Map<String, dynamic>.from(perfil);
      solicitanteNombres = map['nombres']?.toString();
      solicitanteApellidos = map['apellidos']?.toString();
    }

    return SolicitudesPermisos(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      solicitanteId: json['solicitante_id'],
      solicitanteNombres: solicitanteNombres,
      solicitanteApellidos: solicitanteApellidos,
      tipo: TipoPermiso.fromString(json['tipo']),
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      diasTotales: json['dias_totales'],
      motivoDetalle: json['motivo_detalle'],
      documentoSoporteUrl: json['documento_url'],
      estado: json['estado'] != null
          ? EstadoAprobacion.fromString(json['estado'])
          : null,
      aprobadoPorId: json['aprobado_por_id'],
      fechaResolucion: json['fecha_resolucion'] != null
          ? DateTime.parse(json['fecha_resolucion'])
          : null,
      comentarioResolucion: json['comentario_resolucion'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizacion_id': organizacionId,
    'solicitante_id': solicitanteId,
    'tipo': tipo.value,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'fecha_fin': fechaFin.toIso8601String(),
    'dias_totales': diasTotales,
    'motivo_detalle': motivoDetalle,
    'documento_url': documentoSoporteUrl,
    'estado': estado?.value,
    // ...resto de campos
  };
}
