// Mapeo exacto de los ENUMs de PostgreSQL
enum OrgStatus {
  prueba,
  activa,
  suspendida;

  String toJson() => name;
  static OrgStatus fromJson(String json) => values.firstWhere(
        (e) => e.name == json,
        orElse: () => OrgStatus.prueba,
      );
}

enum AttendanceStatus {
  puntual,
  tardanza,
  falta,
  salida_temprana; // camelCase para Dart, snake_case en DB se maneja en el mapper

  String toJson() {
    switch (this) {
      case AttendanceStatus.salida_temprana:
        return 'salida_temprana';
      default:
        return name;
    }
  }

  static AttendanceStatus fromJson(String json) => values.firstWhere(
        (e) => e.toJson() == json,
        orElse: () => AttendanceStatus.puntual,
      );
}

enum ShiftCategory {
  completa,
  reducida,
  corta,
  descanso;

  String toJson() => name;
  static ShiftCategory fromJson(String json) => values.firstWhere(
        (e) => e.name == json,
        orElse: () => ShiftCategory.completa,
      );
}

enum NotifType {
  info,
  alerta,
  sistema;

  String toJson() => name;
  static NotifType fromJson(String json) => values.firstWhere(
        (e) => e.name == json,
        orElse: () => NotifType.info,
      );
}