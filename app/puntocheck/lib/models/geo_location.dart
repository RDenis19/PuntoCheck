/// Helper para manejar columnas GEOGRAPHY(POINT) de PostGIS.
/// Supabase devuelve GeoJSON por defecto: { "type": "Point", "coordinates": [long, lat] }
class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation({required this.latitude, required this.longitude});

  // Parsea el GeoJSON que viene de Supabase
  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    final coordinates = List<double>.from(json['coordinates'] ?? [0.0, 0.0]);
    // PostGIS usa [Longitud, Latitud] en el array
    return GeoLocation(
      longitude: coordinates[0],
      latitude: coordinates[1],
    );
  }

  // Convierte a GeoJSON para enviar a Supabase (PostGIS)
  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
  }

  @override
  String toString() => '$latitude, $longitude';
}