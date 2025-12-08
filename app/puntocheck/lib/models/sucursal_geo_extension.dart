import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'sucursales.dart';

extension SucursalGeoExt on Sucursales {
  LatLng? get centerLatLng {
    final geo = ubicacionCentral;
    if (geo == null) return null;
    final coords = geo['coordinates'];
    if (coords is List && coords.length == 2) {
      final lon = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lon != null && lat != null) {
        return LatLng(lat, lon);
      }
    } else if (geo['lon'] != null || geo['lng'] != null) {
      final lon = (geo['lon'] ?? geo['lng']) as num?;
      final lat = (geo['lat'] ?? geo['latitude']) as num?;
      if (lon != null && lat != null) {
        return LatLng(lat.toDouble(), lon.toDouble());
      }
    } else if (geo['longitude'] != null && geo['latitude'] != null) {
      final lon = geo['longitude'] as num?;
      final lat = geo['latitude'] as num?;
      if (lon != null && lat != null) {
        return LatLng(lat.toDouble(), lon.toDouble());
      }
    }
    return null;
  }
}
