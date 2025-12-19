import 'package:geolocator/geolocator.dart';

class GeoPoint {
  final double lon;
  final double lat;

  const GeoPoint({required this.lon, required this.lat});
}

class GeoUtils {
  GeoUtils._();

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  /// Soporta GeoJSON: {"type":"Point","coordinates":[lon,lat]} o {"lon":..,"lat":..}
  static GeoPoint? tryParsePoint(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final coords = map['coordinates'];
      if (coords is List && coords.length == 2) {
        final lon = _toDouble(coords[0]);
        final lat = _toDouble(coords[1]);
        if (lon != null && lat != null) return GeoPoint(lon: lon, lat: lat);
      }

      final lon = _toDouble(map['lon'] ?? map['lng'] ?? map['longitude']);
      final lat = _toDouble(map['lat'] ?? map['latitude']);
      if (lon != null && lat != null) return GeoPoint(lon: lon, lat: lat);
    }

    if (raw is List && raw.length == 2) {
      final lon = _toDouble(raw[0]);
      final lat = _toDouble(raw[1]);
      if (lon != null && lat != null) return GeoPoint(lon: lon, lat: lat);
    }

    return null;
  }

  static double distanceMeters(GeoPoint a, GeoPoint b) {
    return Geolocator.distanceBetween(a.lat, a.lon, b.lat, b.lon);
  }
}

