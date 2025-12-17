import 'dart:convert';

import 'enums.dart';

class RegistrosAsistencia {
  final String id;
  final String perfilId;
  final String organizacionId;
  final String? sucursalId;
  final String? sucursalNombre;
  final String? perfilNombres;
  final String? perfilApellidos;
  final String? turnoNombreTurno;
  final String? turnoHoraInicio;
  final String? turnoHoraFin;
  final String?
  tipoRegistro; // CHECK ('entrada', 'salida'...) - No es enum en DB
  final DateTime fechaHoraMarcacion;
  final DateTime? fechaHoraSincronizacion;
  final Map<String, dynamic>? ubicacionGps; // GEOGRAPHY/POINT (GeoJSON o WKT)
  final double? ubicacionPrecisionMetros;
  final bool? estaDentroGeocerca;
  final bool? esMockLocation;
  final String evidenciaFotoUrl;
  final OrigenMarcacion? origen;
  final bool? esValidoLegalmente;
  final String? notasSistema;
  final String? turnoJornadaId;
  final bool? eliminado;
  final DateTime? creadoEn;

  RegistrosAsistencia({
    required this.id,
    required this.perfilId,
    required this.organizacionId,
    this.sucursalId,
    this.sucursalNombre,
    this.perfilNombres,
    this.perfilApellidos,
    this.turnoNombreTurno,
    this.turnoHoraInicio,
    this.turnoHoraFin,
    this.tipoRegistro,
    required this.fechaHoraMarcacion,
    this.fechaHoraSincronizacion,
    this.ubicacionGps,
    this.ubicacionPrecisionMetros,
    this.estaDentroGeocerca,
    this.esMockLocation,
    required this.evidenciaFotoUrl,
    this.origen,
    this.esValidoLegalmente,
    this.notasSistema,
    this.turnoJornadaId,
    this.eliminado,
    this.creadoEn,
  });

  String get perfilNombreCompleto {
    final nombres = (perfilNombres ?? '').trim();
    final apellidos = (perfilApellidos ?? '').trim();
    final full = '$nombres $apellidos'.trim();
    if (full.isNotEmpty) return full;
    return 'ID: ${perfilId.substring(0, 8)}';
  }

  static Map<String, dynamic> _normalize(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // ignore and throw below
      }
    }
    throw Exception('Formato de asistencia inválido: $json');
  }

  static Map<String, dynamic>? _parseGeoPoint(dynamic rawGeo) {
    if (rawGeo == null) return null;

    if (rawGeo is Map<String, dynamic>) {
      if (rawGeo.containsKey('coordinates')) return rawGeo;
      if (rawGeo.containsKey('lon') || rawGeo.containsKey('lng')) {
        final lon = (rawGeo['lon'] ?? rawGeo['lng']) as num?;
        final lat = rawGeo['lat'] as num?;
        if (lon != null && lat != null) {
          return {
            'type': 'Point',
            'coordinates': [lon.toDouble(), lat.toDouble()],
          };
        }
      }
      return rawGeo;
    }

    if (rawGeo is Map) {
      return _parseGeoPoint(Map<String, dynamic>.from(rawGeo));
    }

    if (rawGeo is List && rawGeo.length == 2) {
      final lon = (rawGeo[0] as num?)?.toDouble();
      final lat = (rawGeo[1] as num?)?.toDouble();
      if (lon != null && lat != null) {
        return {
          'type': 'Point',
          'coordinates': [lon, lat],
        };
      }
    }

    if (rawGeo is String) {
      final trimmed = rawGeo.trim();

      // GeoJSON como string
      if (trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return _parseGeoPoint(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // ignore and try WKT
        }
      }

      // WKT: "POINT(lon lat)" o "SRID=4326;POINT(lon lat)"
      if (trimmed.contains('POINT')) {
        final start = trimmed.indexOf('(');
        final end = trimmed.indexOf(')');
        if (start != -1 && end != -1 && end > start + 1) {
          final parts = trimmed
              .substring(start + 1, end)
              .split(RegExp(r'\\s+'));
          if (parts.length == 2) {
            final lon = double.tryParse(parts[0]);
            final lat = double.tryParse(parts[1]);
            if (lon != null && lat != null) {
              return {
                'type': 'Point',
                'coordinates': [lon, lat],
              };
            }
          }
        }
      }
    }

    return null;
  }

  factory RegistrosAsistencia.fromJson(Map<String, dynamic> json) {
    final parsedGeo = _parseGeoPoint(json['ubicacion_gps']);

    String? perfilNombres;
    String? perfilApellidos;
    final perfil = json['perfiles'];
    if (perfil is Map) {
      final map = Map<String, dynamic>.from(perfil);
      perfilNombres = map['nombres']?.toString();
      perfilApellidos = map['apellidos']?.toString();
    }

    String? sucursalNombre;
    final sucursal = json['sucursales'];
    if (sucursal is Map) {
      final map = Map<String, dynamic>.from(sucursal);
      sucursalNombre = map['nombre']?.toString();
    }

    String? turnoNombreTurno;
    String? turnoHoraInicio;
    String? turnoHoraFin;
    final turno = json['turnos_jornada'];
    if (turno is Map) {
      final map = Map<String, dynamic>.from(turno);
      turnoNombreTurno = map['nombre_turno']?.toString();
      turnoHoraInicio = map['hora_inicio']?.toString();
      turnoHoraFin = map['hora_fin']?.toString();
    }

    return RegistrosAsistencia(
      id: json['id'],
      perfilId: json['perfil_id'],
      organizacionId: json['organizacion_id'],
      sucursalId: json['sucursal_id'],
      sucursalNombre: sucursalNombre,
      perfilNombres: perfilNombres,
      perfilApellidos: perfilApellidos,
      turnoNombreTurno: turnoNombreTurno,
      turnoHoraInicio: turnoHoraInicio,
      turnoHoraFin: turnoHoraFin,
      tipoRegistro: json['tipo_registro'],
      fechaHoraMarcacion: DateTime.parse(json['fecha_hora_marcacion']),
      fechaHoraSincronizacion:
          (json['fecha_hora_servidor'] ?? json['fecha_hora_sincronizacion']) !=
              null
          ? DateTime.parse(
              json['fecha_hora_servidor'] ?? json['fecha_hora_sincronizacion'],
            )
          : null,
      ubicacionGps: parsedGeo,
      ubicacionPrecisionMetros:
          ((json['precision_metros'] ?? json['ubicacion_precision_metros'])
                  as num?)
              ?.toDouble(),
      estaDentroGeocerca: json['esta_dentro_geocerca'],
      esMockLocation: json['es_mock_location'],
      evidenciaFotoUrl: (json['evidencia_foto_url'] ?? '') as String,
      origen: json['origen'] != null
          ? OrigenMarcacion.fromString(json['origen'])
          : null,
      esValidoLegalmente: json['es_valido_legalmente'],
      notasSistema: (json['notas'] ?? json['notas_sistema']) as String?,
      turnoJornadaId: json['turno_jornada_id'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  factory RegistrosAsistencia.fromDynamic(dynamic json) {
    return RegistrosAsistencia.fromJson(_normalize(json));
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
    'es_mock_location': esMockLocation,
    'evidencia_foto_url': evidenciaFotoUrl,
    'origen': origen?.value,
    'es_valido_legalmente': esValidoLegalmente,
    'notas_sistema': notasSistema,
    'turno_jornada_id': turnoJornadaId,
    'eliminado': eliminado,
  };
}
