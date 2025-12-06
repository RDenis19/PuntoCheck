class PlanesSuscripcion {
  final String id;
  final String nombre;
  final int maxEmpleados;
  final int maxManagers;
  final int storageLimitGb;
  final double precioMensual; // NUMERIC
  final bool? tieneApiAccess;
  final bool? activo;
  final DateTime? creadoEn;
  final Map<String, dynamic>? funcionesAvanzadas;

  PlanesSuscripcion({
    required this.id,
    required this.nombre,
    required this.maxEmpleados,
    required this.maxManagers,
    required this.storageLimitGb,
    required this.precioMensual,
    this.tieneApiAccess,
    this.activo,
    this.creadoEn,
    this.funcionesAvanzadas,
  });

  factory PlanesSuscripcion.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double _parseDouble(dynamic value, {double fallback = 0}) {
      if (value == null) return fallback;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    // El esquema usa `almacenamiento_gb`. Mantenemos compatibilidad con
    // `storage_limit_gb` por si existen datos antiguos.
    final rawStorage = json['almacenamiento_gb'] ?? json['storage_limit_gb'];

    return PlanesSuscripcion(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      maxEmpleados: _parseInt(json['max_empleados']),
      maxManagers: _parseInt(json['max_managers']),
      storageLimitGb: _parseInt(rawStorage, fallback: 5),
      precioMensual: _parseDouble(json['precio_mensual']),
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
    'max_empleados': maxEmpleados,
    'max_managers': maxManagers,
    'almacenamiento_gb': storageLimitGb,
    'precio_mensual': precioMensual,
    'tiene_api_access': tieneApiAccess,
    'activo': activo,
    // creado_en suele ser gestionado por la DB
  };
}
