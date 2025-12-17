import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'sucursales.dart';

extension SucursalGeoExt on Sucursales {
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  LatLng? get centerLatLng {
    final geo = ubicacionCentral;
    if (geo == null) return null;
    final coords = geo['coordinates'];
    if (coords is List && coords.length == 2) {
      final lon = _toDouble(coords[0]);
      final lat = _toDouble(coords[1]);
      if (lon != null && lat != null) {
        return LatLng(lat, lon);
      }
    } else if (geo['lon'] != null || geo['lng'] != null) {
      final lon = _toDouble(geo['lon'] ?? geo['lng'] ?? geo['longitude']);
      final lat = _toDouble(geo['lat'] ?? geo['latitude']);
      if (lon != null && lat != null) {
        return LatLng(lat, lon);
      }
    } else if (geo['longitude'] != null && geo['latitude'] != null) {
      final lon = _toDouble(geo['longitude']);
      final lat = _toDouble(geo['latitude']);
      if (lon != null && lat != null) {
        return LatLng(lat, lon);
      }
    }
    return null;
  }
}
