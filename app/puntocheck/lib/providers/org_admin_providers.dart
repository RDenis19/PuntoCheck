import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/auditoria_log.dart';
import '../models/enums.dart';
import '../models/notificacion.dart';
import '../models/organizaciones.dart';
import '../models/pagos_suscripciones.dart';
import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import 'auth_providers.dart';
import 'core_providers.dart';
import '../services/supabase_client.dart';

// ============================================================================
// Helpers
// ============================================================================
Future<String> _requireOrgId(Ref ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;

  if (orgId == null || orgId.isEmpty) {
    throw Exception('No se pudo resolver la organizacion del admin.');
  }
  return orgId;
}

// ============================================================================
// PROVIDER RAÍZ: Datos base de la organización
// ============================================================================
final orgAdminOrganizationProvider = FutureProvider<Organizaciones>((
  ref,
) async {
  final orgId = await _requireOrgId(ref);
  return ref.read(organizationServiceProvider).getMyOrganization(orgId);
});

// ============================================================================
// Providers Dependientes (Todos esperan a orgAdminOrganizationProvider)
// ============================================================================
final orgAdminStaffProvider =
    FutureProvider.family<List<Perfiles>, OrgAdminPeopleFilter>((
      ref,
      filter,
    ) async {
      final organization = await ref.watch(orgAdminOrganizationProvider.future);

      final staff = await ref
          .read(staffServiceProvider)
          .getStaff(organization.id, searchQuery: filter.search);

      return staff.where((perfil) {
        final matchesRole = filter.role == null || perfil.rol == filter.role;
        final matchesActive =
            filter.active == null || perfil.activo == filter.active;
        return matchesRole && matchesActive;
      }).toList();
    });

final orgAdminAlertsProvider =
    FutureProvider.autoDispose<List<AlertasCumplimiento>>((ref) async {
      // CORREGIDO: Dependencia encadenada
      final organization = await ref.watch(orgAdminOrganizationProvider.future);

      return ref
          .read(complianceServiceProvider)
          .getAlerts(organization.id, onlyPending: true);
    });

final orgAdminPaymentsProvider =
    FutureProvider.autoDispose<List<PagosSuscripciones>>((ref) async {
      // CORREGIDO: Dependencia encadenada
      final organization = await ref.watch(orgAdminOrganizationProvider.future);

      return ref
          .read(paymentsServiceProvider)
          .listPayments(orgId: organization.id);
    });

// Este provider busca managers para el dropdown
final orgAdminManagersProvider = FutureProvider<List<Perfiles>>((ref) async {
  // CORREGIDO: Dependencia encadenada
  final organization = await ref.watch(orgAdminOrganizationProvider.future);

  final staff = await ref.read(staffServiceProvider).getStaff(organization.id);

  return staff
      .where(
        (perfil) =>
            perfil.rol == RolUsuario.manager &&
            perfil.activo == true &&
            perfil.eliminado != true,
      )
      .toList();
});

final orgAdminAuditLogProvider = FutureProvider.autoDispose<List<AuditoriaLog>>(
  (ref) async {
    // CORREGIDO: Dependencia encadenada
    final organization = await ref.watch(orgAdminOrganizationProvider.future);

    return ref
        .read(complianceServiceProvider)
        .getAuditLog(orgId: organization.id, limit: 100);
  },
);

// ============================================================================
// Providers Independientes (No dependen de la Org ID directamente o reciben params)
// ============================================================================

final orgAdminPersonProvider = FutureProvider.family<Perfiles, String>((
  ref,
  userId,
) async {
  return ref.read(staffServiceProvider).getProfile(userId);
});

final orgAdminPersonAttendanceProvider =
    FutureProvider.family<List<RegistrosAsistencia>, String>((
      ref,
      userId,
    ) async {
      return ref
          .read(operationsServiceProvider)
          .getAttendanceLogs(targetUserId: userId, limit: 50);
    });

final orgAdminPermissionsProvider = FutureProvider.autoDispose
    .family<List<SolicitudesPermisos>, bool>((ref, pendingOnly) async {
      // Este servicio internamente ya filtra por la org del usuario logueado
      // o recibe parámetros, pero si necesitas el ID, usa el patrón anterior.
      // Asumiremos que getRequests maneja la seguridad RLS por su cuenta.
      return ref
          .read(complianceServiceProvider)
          .getRequests(pendingOnly: pendingOnly);
    });

final orgAdminAttendanceProvider = FutureProvider.family
    .autoDispose<List<RegistrosAsistencia>, OrgAdminAttendanceFilter>((
      ref,
      filter,
    ) async {
      final start = filter.startDate;
      final end = filter.endDate;
      return ref
          .read(operationsServiceProvider)
          .getAttendanceLogs(
            targetUserId: filter.userId,
            startDate: start,
            endDate: end,
            limit: filter.limit,
          );
    });

// ============================================================================
// Dashboard compacto (Inicio) - OPTIMIZADO
// ============================================================================
class OrgAdminHomeSummary {
  final Organizaciones organization;
  final int staffTotal;
  final int staffActive;
  final int pendingPermissions;
  final int pendingAlerts;
  final int pendingPayments;
  final int attendanceToday;
  final int geofenceIssuesToday;

  OrgAdminHomeSummary({
    required this.organization,
    required this.staffTotal,
    required this.staffActive,
    required this.pendingPermissions,
    required this.pendingAlerts,
    required this.pendingPayments,
    required this.attendanceToday,
    required this.geofenceIssuesToday,
  });
}

final orgAdminHomeSummaryProvider = FutureProvider<OrgAdminHomeSummary>((
  ref,
) async {
  // 1. Obtenemos la Organización primero (Bloqueante pero seguro)
  final organization = await ref.watch(orgAdminOrganizationProvider.future);
  final orgId = organization.id;

  // 2. Ejecutamos todas las demás peticiones en PARALELO para que cargue rápido
  //    (Future.wait es mucho más eficiente que hacer await uno por uno)
  final results = await Future.wait([
    ref.read(staffServiceProvider).getStaff(orgId, orderBy: 'creado_en'),
    ref.read(complianceServiceProvider).getRequests(pendingOnly: true),
    ref.read(complianceServiceProvider).getAlerts(orgId, onlyPending: true),
    ref
        .read(paymentsServiceProvider)
        .listPayments(orgId: orgId, estado: EstadoPago.pendiente),
    _getTodayAttendance(ref), // Helper extraído abajo
  ]);

  // 3. Desempaquetamos resultados
  final staff = results[0] as List<Perfiles>;
  final pendingPerms = results[1] as List<SolicitudesPermisos>;
  final pendingAlerts = results[2] as List<AlertasCumplimiento>;
  final pendingPayments = results[3] as List<PagosSuscripciones>;
  final attendanceToday = results[4] as List<RegistrosAsistencia>;

  final geofenceIssues = attendanceToday
      .where((r) => r.estaDentroGeocerca == false)
      .length;

  final activeCount = staff.where((p) => p.activo != false).length;

  return OrgAdminHomeSummary(
    organization: organization,
    staffTotal: staff.length,
    staffActive: activeCount,
    pendingPermissions: pendingPerms.length,
    pendingAlerts: pendingAlerts.length,
    pendingPayments: pendingPayments.length,
    attendanceToday: attendanceToday.length,
    geofenceIssuesToday: geofenceIssues,
  );
});

// Helper privado para limpiar el provider de summary
Future<List<RegistrosAsistencia>> _getTodayAttendance(Ref ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref
      .read(operationsServiceProvider)
      .getAttendanceLogs(startDate: startOfDay, endDate: now, limit: 200);
}

// ============================================================================
// DTOs para filtros
// ============================================================================
class OrgAdminPeopleFilter {
  final String? search;
  final RolUsuario? role;
  final bool? active;

  const OrgAdminPeopleFilter({this.search, this.role, this.active});

  @override
  bool operator ==(Object other) {
    return other is OrgAdminPeopleFilter &&
        other.search == search &&
        other.role == role &&
        other.active == active;
  }

  @override
  int get hashCode => Object.hash(search, role, active);
}

class OrgAdminAttendanceFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;
  final int limit;

  const OrgAdminAttendanceFilter({
    this.startDate,
    this.endDate,
    this.userId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    return other is OrgAdminAttendanceFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.userId == userId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, userId, limit);
}

// ============================================================================
// Controladores
// ============================================================================
class OrgAdminPermissionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> resolve({
    required String requestId,
    required EstadoAprobacion status,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(complianceServiceProvider)
          .resolveRequest(
            requestId: requestId,
            status: status,
            comment: comment,
          ),
    );

    if (!state.hasError) {
      ref
        ..invalidate(orgAdminPermissionsProvider(false))
        ..invalidate(orgAdminAlertsProvider);
    }
  }
}

final orgAdminPermissionControllerProvider =
    AsyncNotifierProvider<OrgAdminPermissionController, void>(
      OrgAdminPermissionController.new,
    );

// ============================================================================
// Provider para obtener notificaciones del usuario
// ============================================================================
final orgAdminNotificationsProvider =
    FutureProvider.autoDispose<List<Notificacion>>((ref) async {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      return ref.read(complianceServiceProvider).getNotifications(userId);
    });

// ============================================================================
// Provider para obtener conteo de notificaciones no leídas
// ============================================================================
final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 0;

  return ref
      .read(complianceServiceProvider)
      .getUnreadNotificationsCount(userId);
});

// ============================================================================
// Controller para resolver alertas
// ============================================================================
class AlertsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> resolve({
    required String alertId,
    required String newStatus,
    String? justification,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(complianceServiceProvider)
          .resolveAlert(
            alertId: alertId,
            newStatus: newStatus,
            justification: justification,
          ),
    );

    if (!state.hasError) {
      ref.invalidate(orgAdminAlertsProvider);
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await ref
        .read(complianceServiceProvider)
        .markNotificationAsRead(notificationId);

    ref
      ..invalidate(orgAdminNotificationsProvider)
      ..invalidate(unreadNotificationsCountProvider);
  }
}

final alertsControllerProvider = AsyncNotifierProvider<AlertsController, void>(
  AlertsController.new,
);
