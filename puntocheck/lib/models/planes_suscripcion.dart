class PlanesSuscripcion {
  final String id;
  final String nombre;
  final int maxUsuarios;
  final int maxSucursales;
  final int almacenamientoGb;
  final double precioMensual; // NUMERIC
  final bool? tieneApiAccess;
  final bool? activo;
  final DateTime? creadoEn;
  final Map<String, dynamic>? funcionesAvanzadas;

  PlanesSuscripcion({
    required this.id,
    required this.nombre,
    required this.maxUsuarios,
    required this.maxSucursales,
    required this.almacenamientoGb,
    required this.precioMensual,
    this.tieneApiAccess,
    this.activo,
    this.creadoEn,
    this.funcionesAvanzadas,
  });

  factory PlanesSuscripcion.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    // Compatibilidad hacia atrヴs: priorizamos el esquema nuevo
    // (max_usuarios, max_sucursales, almacenamiento_gb) pero aceptamos
    // los nombres antiguos si existen datos legacy.
    final rawMaxUsuarios = json['max_usuarios'] ?? json['max_empleados'];
    final rawMaxSucursales = json['max_sucursales'] ?? json['max_managers'];
    final rawStorage = json['almacenamiento_gb'] ?? json['storage_limit_gb'];

    return PlanesSuscripcion(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      maxUsuarios: parseInt(rawMaxUsuarios),
      maxSucursales: parseInt(rawMaxSucursales, fallback: 1),
      almacenamientoGb: parseInt(rawStorage, fallback: 5),
      precioMensual: parseDouble(json['precio_mensual']),
      tieneApiAccess: json['tiene_api_access'] as bool?,
      activo: json['activo'] as bool?,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
          : null,
      funcionesAvanzadas:
          (json['funciones_avanzadas'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'max_usuarios': maxUsuarios,
    'max_sucursales': maxSucursales,
    'almacenamiento_gb': almacenamientoGb,
    'precio_mensual': precioMensual,
    'activo': activo,
    // creado_en suele ser gestionado por la DB
  };
}
