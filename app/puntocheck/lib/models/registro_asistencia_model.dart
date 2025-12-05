import 'package:puntocheck/models/enums.dart';

class RegistroAsistenciaModel {
  final String id;
  final String perfilId;
  final String organizacionId;
  final String? sucursalId;
  final String tipoRegistro; // 'entrada', 'salida', etc.
  final DateTime fechaHoraMarcacion;
  final Map<String, dynamic>? ubicacionGps; // GeoJSON
  final bool estaDentroGeocerca;
  final String evidenciaFotoUrl;
  final OrigenMarcacion origen;
  final bool esValidoLegalmente;
  final String? notasSistema;

  RegistroAsistenciaModel({
    required this.id,
    required this.perfilId,
    required this.organizacionId,
    this.sucursalId,
    required this.tipoRegistro,
    required this.fechaHoraMarcacion,
    this.ubicacionGps,
    required this.estaDentroGeocerca,
    required this.evidenciaFotoUrl,
    required this.origen,
    required this.esValidoLegalmente,
    this.notasSistema,
  });

  factory RegistroAsistenciaModel.fromJson(Map<String, dynamic> json) {
    return RegistroAsistenciaModel(
      id: json['id'],
      perfilId: json['perfil_id'],
      organizacionId: json['organizacion_id'],
      sucursalId: json['sucursal_id'],
      tipoRegistro: json['tipo_registro'],
      fechaHoraMarcacion: DateTime.parse(json['fecha_hora_marcacion']),
      ubicacionGps: json['ubicacion_gps'],
      estaDentroGeocerca: json['esta_dentro_geocerca'] ?? false,
      evidenciaFotoUrl: json['evidencia_foto_url'] ?? '',
      origen: OrigenMarcacion.fromString(json['origen'] ?? 'gps_movil'),
      esValidoLegalmente: json['es_valido_legalmente'] ?? true,
      notasSistema: json['notas_sistema'],
    );
  }

  // Helper: Obtener Lat/Lng si el GeoJSON es un Point
  // Estructura GeoJSON estándar: {"type": "Point", "coordinates": [long, lat]}
  double? get latitud {
    if (ubicacionGps != null && ubicacionGps!['coordinates'] != null) {
      return ubicacionGps!['coordinates'][1]; // Lat es el segundo
    }
    return null;
  }

  double? get longitud {
    if (ubicacionGps != null && ubicacionGps!['coordinates'] != null) {
      return ubicacionGps!['coordinates'][0]; // Long es el primero
    }
    return null;
  }
}
