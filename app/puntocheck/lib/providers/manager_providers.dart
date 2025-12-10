import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organizaciones.dart';
import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/banco_horas_compensatorias.dart';
import '../services/manager_service.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

// ============================================================================
// Provider del servicio Manager
// ============================================================================
final managerServiceProvider = Provider<ManagerService>((ref) {
  return ManagerService.instance;
});

// ============================================================================
// Helper para obtener el organization_id del manager
// ============================================================================
Future<String> _requireOrgId(Ref ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null || orgId.isEmpty) {
    throw Exception('No se pudo resolver la organización del manager.');
  }
  return orgId;
}

// ============================================================================
// 3.1 - PERFIL DEL MANAGER
// ============================================================================

/// Provider para obtener el perfil del manager actual.
final managerProfileProvider = FutureProvider<Perfiles>((ref) async {
  return ref.read(managerServiceProvider).getMyProfile();
});

/// Provider para obtener la organización del manager.
final managerOrganizationProvider = FutureProvider<Organizaciones>((ref) async {
  final orgId = await _requireOrgId(ref);
  return ref.read(organizationServiceProvider).getMyOrganization(orgId);
});

// ============================================================================
// 3.2 - EQUIPO DE TRABAJO
// ============================================================================

/// Provider para obtener el equipo del manager con búsqueda opcional.
///
/// Uso: ref.watch(managerTeamProvider(searchQuery))
final managerTeamProvider = FutureProvider.family<List<Perfiles>, String?>((
  ref,
  searchQuery,
) async {
  return ref.read(managerServiceProvider).getMyTeam(searchQuery: searchQuery);
});

/// Provider para obtener un empleado específico del equipo.
///
/// Útil para mostrar información detallada de un miembro del equipo.
final managerPersonProvider = FutureProvider.family<Perfiles, String>((
  ref,
  employeeId,
) async {
  // Obtener todo el equipo y buscar por ID
  final team = await ref.read(managerServiceProvider).getMyTeam();
  try {
    return team.firstWhere((e) => e.id == employeeId);
  } catch (e) {
    throw Exception('Empleado no encontrado en el equipo');
  }
});

/// Provider para obtener historial de asistencia de un empleado específico.
///
/// Muestra los últimos 20 registros de asistencia del empleado.
final managerPersonAttendanceProvider = FutureProvider.autoDispose
    .family<List<RegistrosAsistencia>, String>((ref, employeeId) async {
      return ref
          .read(managerServiceProvider)
          .getTeamAttendance(employeeId: employeeId, limit: 20);
    });

// ============================================================================
// BANCO DE HORAS - Gestión de horas compensatorias del equipo
// ============================================================================

/// Provider para obtener movimientos de banco de horas del equipo.
///
/// Puede filtrarse por empleado específico.
final managerTeamHoursBankProvider = FutureProvider.autoDispose
    .family<List<BancoHorasCompensatorias>, String?>((ref, employeeId) async {
      return ref
          .read(managerServiceProvider)
          .getTeamHoursBank(employeeId: employeeId);
    });

// ============================================================================
// DASHBOARD - Resumen del equipo
// ============================================================================

/// Clase que contiene el resumen de estadísticas del equipo para el dashboard.
class ManagerHomeSummary {
  final int teamTotal;
  final int teamPresent;
  final int teamLate;
  final int pendingPermissions;
  final int overtimeHoursWeek;

  ManagerHomeSummary({
    required this.teamTotal,
    required this.teamPresent,
    required this.teamLate,
    required this.pendingPermissions,
    required this.overtimeHoursWeek,
  });
}

/// Provider que calcula estadísticas del equipo para el dashboard.
final managerHomeSummaryProvider = FutureProvider<ManagerHomeSummary>((
  ref,
) async {
  try {
    // Obtener equipo
    final team = await ref.read(managerServiceProvider).getMyTeam();
    final teamTotal = team.length;

    // Obtener asistencia de hoy
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final attendanceToday = await ref
        .read(managerServiceProvider)
        .getTeamAttendance(startDate: startOfDay, endDate: now, limit: 200);

    // Calcular presentes (al menos una entrada hoy)
    final presentEmployeeIds = attendanceToday
        .where((r) => r.tipoRegistro == 'entrada')
        .map((r) => r.perfilId)
        .toSet();
    final teamPresent = presentEmployeeIds.length;

    // TODO: Calcular tardanzas (requiere lógica de horarios)
    final teamLate = 0;

    // Obtener permisos pendientes
    final permissions = await ref
        .read(managerServiceProvider)
        .getTeamPermissions(pendingOnly: true);
    final pendingPermissions = permissions.length;

    // TODO: Calcular horas extra semanales
    final overtimeHoursWeek = 0;

    return ManagerHomeSummary(
      teamTotal: teamTotal,
      teamPresent: teamPresent,
      teamLate: teamLate,
      pendingPermissions: pendingPermissions,
      overtimeHoursWeek: overtimeHoursWeek,
    );
  } catch (e) {
    // En caso de error, retornar valores por defecto
    return ManagerHomeSummary(
      teamTotal: 0,
      teamPresent: 0,
      teamLate: 0,
      pendingPermissions: 0,
      overtimeHoursWeek: 0,
    );
  }
});

// ============================================================================
// ASISTENCIA DEL EQUIPO
// ============================================================================

/// Clase de filtro para asistencia del equipo.
class ManagerAttendanceFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;
  final int limit;

  const ManagerAttendanceFilter({
    this.startDate,
    this.endDate,
    this.employeeId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    return other is ManagerAttendanceFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.employeeId == employeeId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, employeeId, limit);
}

/// Provider para obtener asistencia del equipo con filtros.
final managerTeamAttendanceProvider = FutureProvider.family
    .autoDispose<List<RegistrosAsistencia>, ManagerAttendanceFilter>((
      ref,
      filter,
    ) async {
      return ref
          .read(managerServiceProvider)
          .getTeamAttendance(
            startDate: filter.startDate,
            endDate: filter.endDate,
            employeeId: filter.employeeId,
            limit: filter.limit,
          );
    });

// ============================================================================
// PERMISOS DEL EQUIPO
// ============================================================================

/// Provider para obtener permisos del equipo.
final managerTeamPermissionsProvider = FutureProvider.autoDispose
    .family<List<SolicitudesPermisos>, bool>((ref, pendingOnly) async {
      return ref
          .read(managerServiceProvider)
          .getTeamPermissions(pendingOnly: pendingOnly);
    });

/// Controller para aprobar/rechazar permisos.
class ManagerPermissionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Aprobar permiso.
  Future<void> approve({required String requestId, String? comment}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .approvePermission(requestId: requestId, comment: comment),
    );

    if (!state.hasError) {
      // Invalidar providers de permisos
      ref
        ..invalidate(managerTeamPermissionsProvider(true))
        ..invalidate(managerTeamPermissionsProvider(false))
        ..invalidate(managerHomeSummaryProvider);
    }
  }

  /// Rechazar permiso.
  Future<void> reject({
    required String requestId,
    required String comment,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .rejectPermission(requestId: requestId, comment: comment),
    );

    if (!state.hasError) {
      // Invalidar providers de permisos
      ref
        ..invalidate(managerTeamPermissionsProvider(true))
        ..invalidate(managerTeamPermissionsProvider(false))
        ..invalidate(managerHomeSummaryProvider);
    }
  }
}

final managerPermissionControllerProvider =
    AsyncNotifierProvider<ManagerPermissionController, void>(
      ManagerPermissionController.new,
    );

/// Controller para registrar horas en el banco.
class ManagerHoursBankController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Registrar movimiento de horas.
  Future<void> registerHours({
    required String employeeId,
    required double hours,
    required String concept,
    bool acceptsWaiver = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .registerHours(
            employeeId: employeeId,
            hours: hours,
            concept: concept,
            acceptsWaiver: acceptsWaiver,
          ),
    );

    if (!state.hasError) {
      // Invalidar provider de banco de horas
      ref.invalidate(managerTeamHoursBankProvider);
    }
  }
}

final managerHoursBankControllerProvider =
    AsyncNotifierProvider<ManagerHoursBankController, void>(
      ManagerHoursBankController.new,
    );
