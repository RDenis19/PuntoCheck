class SucursalModel {
  final String id;
  final String nombre;
  final String? direccion;
  final int radioGeocercaMetros;
  final bool tieneQrHabilitado;
  // Para simplificar en UI, convertimos el GEOGRAPHY a coordenadas planas aquí
  final double? latitudCentral;
  final double? longitudCentral;

  SucursalModel({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.radioGeocercaMetros,
    required this.tieneQrHabilitado,
    this.latitudCentral,
    this.longitudCentral,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> json) {
    // Lógica para extraer coordenadas si viene de una query ST_AsGeoJSON
    double? lat, long;
    if (json['ubicacion_central'] != null) {
      // Asumiendo que has hecho un cast o el driver lo devuelve como Map
      final geo = json['ubicacion_central'];
      if (geo is Map && geo['coordinates'] != null) {
        long = (geo['coordinates'][0] as num).toDouble();
        lat = (geo['coordinates'][1] as num).toDouble();
      }
    }

    return SucursalModel(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      radioGeocercaMetros: json['radio_geocerca_metros'] ?? 50,
      tieneQrHabilitado: json['tiene_qr_habilitado'] ?? false,
      latitudCentral: lat,
      longitudCentral: long,
    );
  }
}
