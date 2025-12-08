import 'dart:convert';

class Sucursales {
  final String id;
  final String organizacionId;
  final String nombre;
  final String? direccion;
  // GEOGRAPHY(POINT, 4326) desde Supabase suele venir como GeoJSON o String WKT.
  // Usaremos Map para GeoJSON ({"type": "Point", "coordinates": [lon, lat]})
  final Map<String, dynamic>? ubicacionCentral;
  final int? radioMetros;
  final bool? tieneQrHabilitado;
  final bool? eliminado;
  final DateTime? creadoEn;

  Sucursales({
    required this.id,
    required this.organizacionId,
    required this.nombre,
    this.direccion,
    this.ubicacionCentral,
    this.radioMetros,
    this.tieneQrHabilitado,
    this.eliminado,
    this.creadoEn,
  });

  factory Sucursales.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedGeo;
    final rawGeo = json['ubicacion_central'];
    if (rawGeo is Map<String, dynamic>) {
      // Puede venir como {"type":"Point","coordinates":[lon,lat]} o {"lon":..,"lat":..}
      if (rawGeo.containsKey('coordinates')) {
        parsedGeo = rawGeo;
      } else if (rawGeo.containsKey('lon') || rawGeo.containsKey('lng')) {
        final lon = (rawGeo['lon'] ?? rawGeo['lng']) as num?;
        final lat = rawGeo['lat'] as num?;
        if (lon != null && lat != null) {
          parsedGeo = {
            'type': 'Point',
            'coordinates': [lon.toDouble(), lat.toDouble()],
          };
        }
      }
    } else if (rawGeo is List && rawGeo.length == 2) {
      final lon = (rawGeo[0] as num?)?.toDouble();
      final lat = (rawGeo[1] as num?)?.toDouble();
      if (lon != null && lat != null) {
        parsedGeo = {
          'type': 'Point',
          'coordinates': [lon, lat],
        };
      }
    } else if (rawGeo is String) {
      if (rawGeo.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(rawGeo);
          if (decoded is Map<String, dynamic>) {
            final coords = decoded['coordinates'];
            if (coords is List && coords.length == 2) {
              final lon = (coords[0] as num?)?.toDouble();
              final lat = (coords[1] as num?)?.toDouble();
              if (lon != null && lat != null) {
                parsedGeo = {
                  'type': 'Point',
                  'coordinates': [lon, lat],
                };
              }
            } else {
              final lon = (decoded['lon'] ?? decoded['lng'] ?? decoded['longitude']) as num?;
              final lat = (decoded['lat'] ?? decoded['latitude']) as num?;
              if (lon != null && lat != null) {
                parsedGeo = {
                  'type': 'Point',
                  'coordinates': [lon.toDouble(), lat.toDouble()],
                };
              }
            }
          }
        } catch (_) {
          // ignore and fallback to WKT
        }
      }
      if (parsedGeo == null && rawGeo.contains('POINT')) {
        final start = rawGeo.indexOf('(');
        final end = rawGeo.indexOf(')');
        if (start != -1 && end != -1 && end > start + 1) {
          final parts = rawGeo.substring(start + 1, end).split(' ');
          if (parts.length == 2) {
            final lon = double.tryParse(parts[0]);
            final lat = double.tryParse(parts[1]);
            if (lon != null && lat != null) {
              parsedGeo = {
                'type': 'Point',
                'coordinates': [lon, lat],
              };
            }
          }
        }
      }
    }

    return Sucursales(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      ubicacionCentral: parsedGeo,
      radioMetros: json['radio_metros'],
      tieneQrHabilitado: json['tiene_qr_habilitado'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizacion_id': organizacionId,
    'nombre': nombre,
    'direccion': direccion,
    'ubicacion_central': ubicacionCentral,
    'radio_metros': radioMetros,
    'tiene_qr_habilitado': tieneQrHabilitado,
    'eliminado': eliminado,
  };

  Sucursales copyWith({
    String? id,
    String? organizacionId,
    String? nombre,
    String? direccion,
    Map<String, dynamic>? ubicacionCentral,
    int? radioMetros,
    bool? tieneQrHabilitado,
    bool? eliminado,
    DateTime? creadoEn,
  }) {
    return Sucursales(
      id: id ?? this.id,
      organizacionId: organizacionId ?? this.organizacionId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      ubicacionCentral: ubicacionCentral ?? this.ubicacionCentral,
      radioMetros: radioMetros ?? this.radioMetros,
      tieneQrHabilitado: tieneQrHabilitado ?? this.tieneQrHabilitado,
      eliminado: eliminado ?? this.eliminado,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
