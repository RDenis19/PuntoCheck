// CREATE TYPE rol_usuario
enum RolUsuario {
  superAdmin('super_admin'),
  orgAdmin('org_admin'),
  manager('manager'),
  auditor('auditor'),
  employee('employee');

  final String value;
  const RolUsuario(this.value);

  factory RolUsuario.fromString(String value) => RolUsuario.values.firstWhere(
    (e) => e.value == value,
    orElse: () => throw Exception('Rol desconocido: $value'),
  );
}

// CREATE TYPE estado_suscripcion
enum EstadoSuscripcion {
  prueba('prueba'),
  activo('activo'),
  vencido('vencido'),
  cancelado('cancelado');

  final String value;
  const EstadoSuscripcion(this.value);

  factory EstadoSuscripcion.fromString(String value) =>
      EstadoSuscripcion.values.firstWhere((e) => e.value == value);
}

// CREATE TYPE tipo_permiso
enum TipoPermiso {
  enfermedad('enfermedad'),
  maternidadPaternidad('maternidad_paternidad'),
  calamidadDomestica('calamidad_domestica'),
  vacaciones('vacaciones'),
  legalVotacion('legal_votacion'),
  otro('otro');

  final String value;
  const TipoPermiso(this.value);

  factory TipoPermiso.fromString(String value) =>
      TipoPermiso.values.firstWhere((e) => e.value == value);
}

// CREATE TYPE estado_aprobacion
enum EstadoAprobacion {
  pendiente('pendiente'),
  aprobado('aprobado'),
  rechazado('rechazado'),
  escalado('escalado');

  final String value;
  const EstadoAprobacion(this.value);

  factory EstadoAprobacion.fromString(String value) =>
      EstadoAprobacion.values.firstWhere((e) => e.value == value);
}

// CREATE TYPE origen_marcacion
enum OrigenMarcacion {
  gpsMovil('gps_movil'),
  qrFijo('qr_fijo'),
  offlineSync('offline_sync');

  final String value;
  const OrigenMarcacion(this.value);

  factory OrigenMarcacion.fromString(String value) =>
      OrigenMarcacion.values.firstWhere((e) => e.value == value);
}

// CREATE TYPE gravedad_alerta
enum GravedadAlerta {
  leve('leve'),
  moderada('moderada'),
  graveLegal('grave_legal');

  final String value;
  const GravedadAlerta(this.value);

  factory GravedadAlerta.fromString(String value) =>
      GravedadAlerta.values.firstWhere((e) => e.value == value);
}
