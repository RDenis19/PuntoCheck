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
  });

  factory PlanesSuscripcion.fromJson(Map<String, dynamic> json) {
    return PlanesSuscripcion(
      id: json['id'],
      nombre: json['nombre'],
      maxEmpleados: json['max_empleados'],
      maxManagers: json['max_managers'],
      storageLimitGb: json['storage_limit_gb'],
      precioMensual: (json['precio_mensual'] as num).toDouble(),
      tieneApiAccess: json['tiene_api_access'],
      activo: json['activo'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'max_empleados': maxEmpleados,
    'max_managers': maxManagers,
    'storage_limit_gb': storageLimitGb,
    'precio_mensual': precioMensual,
    'tiene_api_access': tieneApiAccess,
    'activo': activo,
    // creado_en suele ser gestionado por la DB
  };
}
