// lib/models/enums.dart

enum RolUsuario {
  superAdmin,
  orgAdmin,
  manager,
  auditor,
  employee;

  // Método helper para parsear string a Enum
  static RolUsuario fromString(String val) {
    return switch (val) {
      'super_admin' => RolUsuario.superAdmin,
      'org_admin' => RolUsuario.orgAdmin,
      'manager' => RolUsuario.manager,
      'auditor' => RolUsuario.auditor,
      'employee' => RolUsuario.employee,
      _ => RolUsuario.employee, // Fallback seguro
    };
  }

  String toDbString() {
    return switch (this) {
      RolUsuario.superAdmin => 'super_admin',
      RolUsuario.orgAdmin => 'org_admin',
      RolUsuario.manager => 'manager',
      RolUsuario.auditor => 'auditor',
      RolUsuario.employee => 'employee',
    };
  }
}

enum EstadoSuscripcion { prueba, activo, vencido, cancelado }

enum TipoPermiso {
  enfermedad,
  maternidadPaternidad,
  calamidadDomestica,
  vacaciones,
  legalVotacion,
  otro;

  static TipoPermiso fromString(String val) {
    // Mapeo simple manejando camelCase manual si es necesario
    if (val == 'maternidad_paternidad') return TipoPermiso.maternidadPaternidad;
    if (val == 'calamidad_domestica') return TipoPermiso.calamidadDomestica;
    if (val == 'legal_votacion') return TipoPermiso.legalVotacion;
    return TipoPermiso.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TipoPermiso.otro,
    );
  }

  String toDbString() {
    if (this == TipoPermiso.maternidadPaternidad)
      return 'maternidad_paternidad';
    if (this == TipoPermiso.calamidadDomestica) return 'calamidad_domestica';
    if (this == TipoPermiso.legalVotacion) return 'legal_votacion';
    return name;
  }
}

enum EstadoAprobacion { pendiente, aprobado, rechazado, escalado }

enum OrigenMarcacion {
  gpsMovil,
  qrFijo,
  offlineSync;

  static OrigenMarcacion fromString(String val) {
    if (val == 'gps_movil') return OrigenMarcacion.gpsMovil;
    if (val == 'qr_fijo') return OrigenMarcacion.qrFijo;
    if (val == 'offline_sync') return OrigenMarcacion.offlineSync;
    return OrigenMarcacion.gpsMovil;
  }
}
