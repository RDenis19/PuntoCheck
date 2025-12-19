import 'enums.dart';

class ConfiguracionPermisos {
  final String id;
  final String organizacionId;
  final TipoPermiso tipoPermiso;
  final int? maxDiasAnual;
  final bool? requiereCertificado;
  final int? diasAnticipacionMinima;
  final bool? requiereDobleAprobacion;
  final String? mensajeLegalAyuda;

  ConfiguracionPermisos({
    required this.id,
    required this.organizacionId,
    required this.tipoPermiso,
    this.maxDiasAnual,
    this.requiereCertificado,
    this.diasAnticipacionMinima,
    this.requiereDobleAprobacion,
    this.mensajeLegalAyuda,
  });

  factory ConfiguracionPermisos.fromJson(Map<String, dynamic> json) {
    return ConfiguracionPermisos(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      tipoPermiso: TipoPermiso.fromString(json['tipo_permiso']),
      maxDiasAnual: json['max_dias_anual'],
      requiereCertificado: json['requiere_certificado'],
      diasAnticipacionMinima: json['dias_anticipacion_minima'],
      requiereDobleAprobacion: json['requiere_doble_aprobacion'],
      mensajeLegalAyuda: json['mensaje_legal_ayuda'],
    );
  }
}
