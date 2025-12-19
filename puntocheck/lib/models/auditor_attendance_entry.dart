import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/sucursales.dart';

/// Entrada de asistencia enriquecida para auditoría:
/// - Registro base
/// - Datos del empleado (perfil)
/// - Datos de la sucursal (incluye ubicación/radio si vienen embebidos)
class AuditorAttendanceEntry {
  final RegistrosAsistencia record;
  final Perfiles? employee;
  final Sucursales? branch;

  const AuditorAttendanceEntry({
    required this.record,
    required this.employee,
    required this.branch,
  });

  factory AuditorAttendanceEntry.fromJson(Map<String, dynamic> json) {
    final employeeRaw = json['perfiles'];
    final branchRaw = json['sucursales'];
    return AuditorAttendanceEntry(
      record: RegistrosAsistencia.fromJson(json),
      employee: employeeRaw is Map
          ? Perfiles.fromJson(Map<String, dynamic>.from(employeeRaw))
          : null,
      branch: branchRaw is Map
          ? Sucursales.fromJson(Map<String, dynamic>.from(branchRaw))
          : null,
    );
  }

  factory AuditorAttendanceEntry.fromDynamic(dynamic json) {
    if (json is Map<String, dynamic>) return AuditorAttendanceEntry.fromJson(json);
    if (json is Map) {
      return AuditorAttendanceEntry.fromJson(Map<String, dynamic>.from(json));
    }
    throw Exception('Formato de asistencia (auditor) inválido: $json');
  }
}

