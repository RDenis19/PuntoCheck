import 'enums.dart';

class RegistrosAsistencia {
  final String id;
  final String perfilId;
  final String organizacionId;
  final String? sucursalId;
  final String?
  tipoRegistro; // CHECK ('entrada', 'salida'...) - No es enum en DB
  final DateTime fechaHoraMarcacion;
  final DateTime? fechaHoraSincronizacion;
  final Map<String, dynamic>? ubicacionGps; // GEOGRAPHY
  final double? ubicacionPrecisionMetros;
  final bool? estaDentroGeocerca;
  final String evidenciaFotoUrl;
  final OrigenMarcacion? origen;
  final String? deviceId;
  final bool? esValidoLegalmente;
  final String? notasSistema;
  final bool? eliminado;
  final DateTime? creadoEn;

  RegistrosAsistencia({
    required this.id,
    required this.perfilId,
    required this.organizacionId,
    this.sucursalId,
    this.tipoRegistro,
    required this.fechaHoraMarcacion,
    this.fechaHoraSincronizacion,
    this.ubicacionGps,
    this.ubicacionPrecisionMetros,
    this.estaDentroGeocerca,
    required this.evidenciaFotoUrl,
    this.origen,
    this.deviceId,
    this.esValidoLegalmente,
    this.notasSistema,
    this.eliminado,
    this.creadoEn,
  });

  factory RegistrosAsistencia.fromJson(Map<String, dynamic> json) {
    return RegistrosAsistencia(
      id: json['id'],
      perfilId: json['perfil_id'],
      organizacionId: json['organizacion_id'],
      sucursalId: json['sucursal_id'],
      tipoRegistro: json['tipo_registro'],
      fechaHoraMarcacion: DateTime.parse(json['fecha_hora_marcacion']),
      fechaHoraSincronizacion: json['fecha_hora_sincronizacion'] != null
          ? DateTime.parse(json['fecha_hora_sincronizacion'])
          : null,
      ubicacionGps: json['ubicacion_gps'],
      ubicacionPrecisionMetros: (json['ubicacion_precision_metros'] as num?)
          ?.toDouble(),
      estaDentroGeocerca: json['esta_dentro_geocerca'],
      evidenciaFotoUrl: json['evidencia_foto_url'],
      origen: json['origen'] != null
          ? OrigenMarcacion.fromString(json['origen'])
          : null,
      deviceId: json['device_id'],
      esValidoLegalmente: json['es_valido_legalmente'],
      notasSistema: json['notas_sistema'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'perfil_id': perfilId,
    'organizacion_id': organizacionId,
    'sucursal_id': sucursalId,
    'tipo_registro': tipoRegistro,
    'fecha_hora_marcacion': fechaHoraMarcacion.toIso8601String(),
    'fecha_hora_sincronizacion': fechaHoraSincronizacion?.toIso8601String(),
    'ubicacion_gps': ubicacionGps,
    'ubicacion_precision_metros': ubicacionPrecisionMetros,
    'esta_dentro_geocerca': estaDentroGeocerca,
    'evidencia_foto_url': evidenciaFotoUrl,
    'origen': origen?.value,
    'device_id': deviceId,
    'es_valido_legalmente': esValidoLegalmente,
    'notas_sistema': notasSistema,
    'eliminado': eliminado,
  };
}
