/// Modelo de filtros de asistencia (reutilizable por Admin/Manager).
class AttendanceFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;
  final String? branchId;
  final List<String>? types; // entrada, salida, inicio_break, fin_break
  final bool? insideGeofence; // true, false, null = todos

  const AttendanceFilters({
    this.startDate,
    this.endDate,
    this.employeeId,
    this.branchId,
    this.types,
    this.insideGeofence,
  });

  AttendanceFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? branchId,
    List<String>? types,
    bool? insideGeofence,
  }) {
    return AttendanceFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      employeeId: employeeId ?? this.employeeId,
      branchId: branchId ?? this.branchId,
      types: types ?? this.types,
      insideGeofence: insideGeofence ?? this.insideGeofence,
    );
  }

  bool get hasActiveFilters {
    return employeeId != null ||
        branchId != null ||
        (types != null && types!.isNotEmpty) ||
        insideGeofence != null;
  }
}
