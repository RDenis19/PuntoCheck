import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/organizaciones.dart';
import '../models/encargados_sucursales.dart';
import '../models/enums.dart';
import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/banco_horas_compensatorias.dart';
import '../models/plantillas_horarios.dart';
import '../models/sucursales.dart';
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
// 1 - SUCURSAL DEL MANAGER + ENCARGADOS
// ============================================================================

/// Sucursales donde el usuario actual es encargado (manager).
final managerBranchesProvider = FutureProvider.autoDispose<List<Sucursales>>((
  ref,
) async {
  return ref.read(managerServiceProvider).getManagedBranches();
});

/// Encargados (managers) asignados a una sucursal.
final managerBranchManagersProvider = FutureProvider.autoDispose
    .family<List<EncargadosSucursales>, String>((ref, branchId) async {
      return ref.read(staffServiceProvider).getBranchManagers(branchId);
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

/// Igual que `managerTeamProvider`, pero incluye inactivos/eliminados.
final managerTeamAllProvider = FutureProvider.family<List<Perfiles>, String?>((
  ref,
  searchQuery,
) async {
  return ref.read(managerServiceProvider).getMyTeam(
        searchQuery: searchQuery,
        includeDeleted: true,
      );
});

/// Provider para obtener un empleado específico del equipo.
///
/// Útil para mostrar información detallada de un miembro del equipo.
final managerPersonProvider = FutureProvider.family<Perfiles, String>((
  ref,
  employeeId,
) async {
  final managedBranches = await ref.watch(managerBranchesProvider.future);
  final profile = await ref.read(staffServiceProvider).getProfile(employeeId);

  final branchOk =
      profile.sucursalId != null &&
      managedBranches.any((b) => b.id == profile.sucursalId);
  if (!branchOk) throw Exception('Empleado no pertenece a tus sucursales');

  if (profile.rol != RolUsuario.employee) {
    throw Exception('Solo puedes ver empleados de tu equipo');
  }

  return profile;
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
  final List<SolicitudesPermisos> recentPermissions;

  ManagerHomeSummary({
    required this.teamTotal,
    required this.teamPresent,
    required this.teamLate,
    required this.pendingPermissions,
    required this.overtimeHoursWeek,
    required this.recentPermissions,
  });
}

/// Provider que calcula estadísticas del equipo para el dashboard.
/// Provider que calcula estadísticas del equipo para el dashboard (Actualizado automáticamente).
final managerHomeSummaryProvider = StreamProvider.autoDispose<ManagerHomeSummary>((ref) async* {
  // Función auxiliar para obtener datos
  Future<ManagerHomeSummary> fetchData() async {
    try {
      final team = await ref.read(managerServiceProvider).getMyTeam();
      final teamTotal = team.length;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final attendanceToday = await ref
          .read(managerServiceProvider)
          .getTeamAttendance(startDate: startOfDay, endDate: now, limit: 200);

      final presentEmployeeIds = attendanceToday
          .where((r) => r.tipoRegistro == 'entrada')
          .map((r) => r.perfilId)
          .toSet();
      final teamPresent = presentEmployeeIds.length;

      final teamLate = 0; // Logíca pendiente de tardanzas

      final pendingPermissionsList = await ref
          .read(managerServiceProvider)
          .getTeamPermissions(pendingOnly: true);
      final pendingPermissions = pendingPermissionsList.length;

      final overtimeHoursWeek = 0; // Lógica pendiente

      return ManagerHomeSummary(
        teamTotal: teamTotal,
        teamPresent: teamPresent,
        teamLate: teamLate,
        pendingPermissions: pendingPermissions,
        overtimeHoursWeek: overtimeHoursWeek,
        recentPermissions: pendingPermissionsList.take(3).toList(),
      );
    } catch (e) {
       // Retornar vacío en error para no romper stream
       return ManagerHomeSummary(
          teamTotal: 0, 
          teamPresent: 0, 
          teamLate: 0, 
          pendingPermissions: 0, 
          overtimeHoursWeek: 0, 
          recentPermissions: []
       );
    }
  }

  // Emitir primer valor inmediatamente
  yield await fetchData();

  // Loop para actualizar cada 15 segundos
  final timer = Stream.periodic(const Duration(seconds: 15), (i) => i);
  await for (final _ in timer) {
    // Verificar si el provider fue dispuesto para detener
    // (StreamProvider.autoDispose lo maneja cancelando la subscripción)
    yield await fetchData();
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

// ============================================================================
// NOTIFICACIONES DEL MANAGER
// ============================================================================

final managerNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    return ref.read(managerServiceProvider).getMyNotifications();
  },
);

final managerUnreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(managerNotificationsProvider.future);
  return list.where((n) => n['leido'] != true).length;
});

class ManagerNotificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> markRead(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .markNotificationAsRead(notificationId),
    );
    if (!state.hasError) {
      ref.invalidate(managerNotificationsProvider);
    }
  }

  Future<void> markAllRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final list = await ref.read(managerNotificationsProvider.future);
      final unread = list.where((n) => n['leido'] != true).toList();
      for (final item in unread) {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await ref.read(managerServiceProvider).markNotificationAsRead(id);
      }
    });

    if (!state.hasError) {
      ref.invalidate(managerNotificationsProvider);
    }
  }
}

final managerNotificationControllerProvider =
    AsyncNotifierProvider<ManagerNotificationController, void>(
      ManagerNotificationController.new,
    );

// ============================================================================
// PLANTILLAS / ASIGNACIONES DE HORARIOS
// ============================================================================

final managerScheduleTemplatesProvider =
    FutureProvider<List<PlantillasHorarios>>((ref) async {
      return ref.read(managerServiceProvider).getScheduleTemplates();
    });

class ManagerScheduleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> assignSchedule({
    required String employeeId,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .assignSchedule(
            employeeId: employeeId,
            templateId: templateId,
            startDate: startDate,
            endDate: endDate,
          ),
    );
  }

  Future<void> assignScheduleBulk({
    required List<String> employeeIds,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .assignScheduleBulk(
            employeeIds: employeeIds,
            templateId: templateId,
            startDate: startDate,
            endDate: endDate,
          ),
    );
  }

  Future<void> updateSchedule({
    required String assignmentId,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .updateSchedule(
            assignmentId: assignmentId,
            templateId: templateId,
            startDate: startDate,
            endDate: endDate,
          ),
    );
  }
}

final managerScheduleControllerProvider =
    AsyncNotifierProvider<ManagerScheduleController, void>(
      ManagerScheduleController.new,
    );

// ============================================================================
// ASIGNACIONES DE HORARIO (LISTADOS)
// ============================================================================

final managerTeamSchedulesProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, String?>((ref, employeeId) async {
      return ref
          .read(managerServiceProvider)
          .getTeamSchedules(employeeId: employeeId);
    });

final managerEmployeeActiveScheduleProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, employeeId) async {
      return ref
          .read(managerServiceProvider)
          .getEmployeeActiveSchedule(employeeId);
    });

// ============================================================================
// ALERTAS DE CUMPLIMIENTO (Manager)
// ============================================================================

final managerComplianceAlertsProvider = FutureProvider.autoDispose
    .family<List<AlertasCumplimiento>, bool>((ref, pendingOnly) async {
      return ref
          .read(managerServiceProvider)
          .getTeamComplianceAlerts(pendingOnly: pendingOnly);
    });

class ManagerComplianceAlertController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> updateStatus({
    required String alertId,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(managerServiceProvider)
          .updateComplianceAlertStatus(alertId: alertId, status: status),
    );

    if (!state.hasError) {
      ref
        ..invalidate(managerComplianceAlertsProvider(true))
        ..invalidate(managerComplianceAlertsProvider(false))
        ..invalidate(managerHomeSummaryProvider);
    }
  }
}

final managerComplianceAlertControllerProvider =
    AsyncNotifierProvider<ManagerComplianceAlertController, void>(
      ManagerComplianceAlertController.new,
    );
