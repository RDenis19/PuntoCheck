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

  factory TipoPermiso.fromString(String value) {
    final normalized = value.trim().toLowerCase();

    // Compatibilidad por si en la BD existen valores antiguos.
    if (normalized == 'maternidad' || normalized == 'paternidad') {
      return TipoPermiso.maternidadPaternidad;
    }

    for (final item in TipoPermiso.values) {
      if (item.value == normalized) return item;
    }
    return TipoPermiso.otro;
  }

  String get label {
    switch (this) {
      case TipoPermiso.enfermedad:
        return 'Enfermedad';
      case TipoPermiso.maternidadPaternidad:
        return 'Maternidad/Paternidad';
      case TipoPermiso.calamidadDomestica:
        return 'Calamidad Doméstica';
      case TipoPermiso.vacaciones:
        return 'Vacaciones';
      case TipoPermiso.legalVotacion:
        return 'Permiso Legal/Votación';
      case TipoPermiso.otro:
        return 'Otro';
    }
  }
}

// CREATE TYPE estado_aprobacion
enum EstadoAprobacion {
  pendiente('pendiente'),
  aprobadoManager('aprobado_manager'),
  aprobadoRrhh('aprobado_admin'),
  rechazado('rechazado'),
  canceladoUsuario('cancelado_usuario');

  final String value;
  const EstadoAprobacion(this.value);

  factory EstadoAprobacion.fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final item in EstadoAprobacion.values) {
      if (item.value == normalized) return item;
    }
    return EstadoAprobacion.pendiente;
  }

  // Helper para saber si está aprobado (cualquier tipo)
  bool get esAprobado =>
      this == EstadoAprobacion.aprobadoManager ||
      this == EstadoAprobacion.aprobadoRrhh;

  // Helper para saber si está pendiente o puede modificarse
  bool get esPendiente => this == EstadoAprobacion.pendiente;

  String get label {
    switch (this) {
      case EstadoAprobacion.pendiente:
        return 'Pendiente';
      case EstadoAprobacion.aprobadoManager:
        return 'Aprobado por Manager';
      case EstadoAprobacion.aprobadoRrhh:
        return 'Aprobado por RRHH';
      case EstadoAprobacion.rechazado:
        return 'Rechazado';
      case EstadoAprobacion.canceladoUsuario:
        return 'Cancelado por Usuario';
    }
  }
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

  factory GravedadAlerta.fromString(String value) {
    final normalized = value.trim().toLowerCase();

    // Compatibilidad con valores antiguos/alternativos en BD.
    if (normalized == 'advertencia' || normalized == 'warning') {
      return GravedadAlerta.leve;
    }
    if (normalized == 'alta') return GravedadAlerta.graveLegal;
    if (normalized == 'media') return GravedadAlerta.moderada;
    if (normalized == 'baja') return GravedadAlerta.leve;

    for (final item in GravedadAlerta.values) {
      if (item.value == normalized) return item;
    }
    return GravedadAlerta.leve;
  }
}

// Mapeo del tipo SQL: public.estado_pago
enum EstadoPago {
  pendiente('pendiente'),
  aprobado('aprobado'),
  rechazado('rechazado');

  final String value;
  const EstadoPago(this.value);

  factory EstadoPago.fromString(String value) {
    return EstadoPago.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw Exception('Estado de pago desconocido: $value'),
    );
  }
}
