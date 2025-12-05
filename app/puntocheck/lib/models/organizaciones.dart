import 'enums.dart';

class Organizaciones {
  final String id;
  final String ruc;
  final String razonSocial;
  final String? planId;
  final EstadoSuscripcion? estadoSuscripcion;
  final DateTime? fechaInicioSuscripcion;
  final DateTime? fechaFinSuscripcion;
  final Map<String, dynamic>? configuracionLegal; // JSONB
  final String? logoUrl;
  final bool? eliminado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  Organizaciones({
    required this.id,
    required this.ruc,
    required this.razonSocial,
    this.planId,
    this.estadoSuscripcion,
    this.fechaInicioSuscripcion,
    this.fechaFinSuscripcion,
    this.configuracionLegal,
    this.logoUrl,
    this.eliminado,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Organizaciones.fromJson(Map<String, dynamic> json) {
    return Organizaciones(
      id: json['id'],
      ruc: json['ruc'],
      razonSocial: json['razon_social'],
      planId: json['plan_id'],
      estadoSuscripcion: json['estado_suscripcion'] != null
          ? EstadoSuscripcion.fromString(json['estado_suscripcion'])
          : null,
      fechaInicioSuscripcion: json['fecha_inicio_suscripcion'] != null
          ? DateTime.parse(json['fecha_inicio_suscripcion'])
          : null,
      fechaFinSuscripcion: json['fecha_fin_suscripcion'] != null
          ? DateTime.parse(json['fecha_fin_suscripcion'])
          : null,
      configuracionLegal: json['configuracion_legal'],
      logoUrl: json['logo_url'],
      eliminado: json['eliminado'],
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
    'ruc': ruc,
    'razon_social': razonSocial,
    'plan_id': planId,
    'estado_suscripcion': estadoSuscripcion?.value,
    'configuracion_legal': configuracionLegal,
    'logo_url': logoUrl,
    'eliminado': eliminado,
  };
}
