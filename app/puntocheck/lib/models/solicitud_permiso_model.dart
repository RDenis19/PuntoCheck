import 'package:puntocheck/models/enums.dart';

class SolicitudPermisoModel {
  final String id;
  final String solicitanteId;
  final TipoPermiso tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int diasTotales;
  final String? motivoDetalle;
  final String? documentoSoporteUrl;
  final EstadoAprobacion estado;
  final String? comentarioResolucion;

  SolicitudPermisoModel({
    required this.id,
    required this.solicitanteId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.diasTotales,
    this.motivoDetalle,
    this.documentoSoporteUrl,
    required this.estado,
    this.comentarioResolucion,
  });

  factory SolicitudPermisoModel.fromJson(Map<String, dynamic> json) {
    return SolicitudPermisoModel(
      id: json['id'],
      solicitanteId: json['solicitante_id'],
      tipo: TipoPermiso.fromString(json['tipo']),
      fechaInicio: DateTime.parse(json['fecha_inicio']), // Formato YYYY-MM-DD
      fechaFin: DateTime.parse(json['fecha_fin']),
      diasTotales: json['dias_totales'],
      motivoDetalle: json['motivo_detalle'],
      documentoSoporteUrl: json['documento_soporte_url'],
      estado: EstadoAprobacion.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoAprobacion.pendiente,
      ),
      comentarioResolucion: json['comentario_resolucion'],
    );
  }

  Map<String, dynamic> toJsonCreacion() {
    return {
      'tipo': tipo.toDbString(),
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0], // Solo fecha
      'fecha_fin': fechaFin.toIso8601String().split('T')[0],
      'dias_totales': diasTotales,
      'motivo_detalle': motivoDetalle,
      'documento_soporte_url': documentoSoporteUrl,
    };
  }
}
