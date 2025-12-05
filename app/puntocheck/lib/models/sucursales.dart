class Sucursales {
  final String id;
  final String organizacionId;
  final String nombre;
  final String? direccion;
  // GEOGRAPHY(POINT, 4326) desde Supabase suele venir como GeoJSON o String WKT.
  // Usaremos Map para GeoJSON ({"type": "Point", "coordinates": [lon, lat]})
  final Map<String, dynamic>? ubicacionCentral;
  final int? radioGeocercaMetros;
  final bool? tieneQrHabilitado;
  final bool? eliminado;
  final DateTime? creadoEn;

  Sucursales({
    required this.id,
    required this.organizacionId,
    required this.nombre,
    this.direccion,
    this.ubicacionCentral,
    this.radioGeocercaMetros,
    this.tieneQrHabilitado,
    this.eliminado,
    this.creadoEn,
  });

  factory Sucursales.fromJson(Map<String, dynamic> json) {
    return Sucursales(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      ubicacionCentral: json['ubicacion_central'],
      radioGeocercaMetros: json['radio_geocerca_metros'],
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
    'radio_geocerca_metros': radioGeocercaMetros,
    'tiene_qr_habilitado': tieneQrHabilitado,
    'eliminado': eliminado,
  };
}
