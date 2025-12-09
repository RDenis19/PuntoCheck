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
// Datos base del admin de organizacion
// ============================================================================
final orgAdminOrganizationProvider =
    FutureProvider<Organizaciones>((ref) async {
      final orgId = await _requireOrgId(ref);
      return ref.read(organizationServiceProvider).getMyOrganization(orgId);
    });

final orgAdminPersonProvider =
    FutureProvider.family<Perfiles, String>((ref, userId) async {
      return ref.read(staffServiceProvider).getProfile(userId);
    });

final orgAdminPersonAttendanceProvider =
    FutureProvider.family<List<RegistrosAsistencia>, String>(
  (ref, userId) async {
    return ref
        .read(operationsServiceProvider)
        .getAttendanceLogs(targetUserId: userId, limit: 50);
  },
);

final orgAdminStaffProvider = FutureProvider.family<List<Perfiles>,
    OrgAdminPeopleFilter>((ref, filter) async {
  final orgId = await _requireOrgId(ref);
  final staff = await ref
      .read(staffServiceProvider)
      .getStaff(orgId, searchQuery: filter.search);
  return staff.where((perfil) {
    final matchesRole = filter.role == null || perfil.rol == filter.role;
    final matchesActive =
        filter.active == null || perfil.activo == filter.active;
    return matchesRole && matchesActive;
  }).toList();
});

final orgAdminAlertsProvider =
    FutureProvider.autoDispose<List<AlertasCumplimiento>>((ref) async {
      final orgId = await _requireOrgId(ref);
      return ref
          .read(complianceServiceProvider)
          .getAlerts(orgId, onlyPending: true);
    });

final orgAdminPermissionsProvider = FutureProvider.autoDispose
    .family<List<SolicitudesPermisos>, bool>((ref, pendingOnly) async {
      return ref
          .read(complianceServiceProvider)
          .getRequests(pendingOnly: pendingOnly);
    });

final orgAdminPaymentsProvider =
    FutureProvider.autoDispose<List<PagosSuscripciones>>((ref) async {
      final orgId = await _requireOrgId(ref);
      return ref
          .read(paymentsServiceProvider)
          .listPayments(orgId: orgId);
    });

final orgAdminAttendanceProvider = FutureProvider.family
    .autoDispose<List<RegistrosAsistencia>, OrgAdminAttendanceFilter>(
  (ref, filter) async {
    final start = filter.startDate;
    final end = filter.endDate;
    return ref.read(operationsServiceProvider).getAttendanceLogs(
          targetUserId: filter.userId,
          startDate: start,
          endDate: end,
          limit: filter.limit,
        );
  },
);

// ============================================================================
// Dashboard compacto (Inicio)
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

final orgAdminHomeSummaryProvider =
    FutureProvider<OrgAdminHomeSummary>((ref) async {
      final orgId = await _requireOrgId(ref);

      final organization =
          await ref.read(organizationServiceProvider).getMyOrganization(orgId);

      final staff =
          await ref.read(staffServiceProvider).getStaff(orgId, orderBy: 'creado_en');
      final pendingPerms =
          await ref.read(complianceServiceProvider).getRequests(pendingOnly: true);
      final pendingAlerts =
          await ref.read(complianceServiceProvider).getAlerts(orgId, onlyPending: true);
      final pendingPayments = await ref
          .read(paymentsServiceProvider)
          .listPayments(orgId: orgId, estado: EstadoPago.pendiente);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final attendanceToday =
          await ref.read(operationsServiceProvider).getAttendanceLogs(
                startDate: startOfDay,
                endDate: now,
                limit: 200,
              );

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

// ============================================================================
// DTOs para filtros
// ============================================================================
class OrgAdminPeopleFilter {
  final String? search;
  final RolUsuario? role;
  final bool? active;

  const OrgAdminPeopleFilter({
    this.search,
    this.role,
    this.active,
  });

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
          .resolveRequest(requestId: requestId, status: status, comment: comment),
    );

    if (!state.hasError) {
      // Invalidar TODAS las solicitudes (false) en lugar de solo pendientes
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
// Provider para obtener lista de managers de la organización
// Usado en selector de jefe inmediato
// ============================================================================
final orgAdminManagersProvider = FutureProvider<List<Perfiles>>((ref) async {
  final orgId = await _requireOrgId(ref);
  final staff = await ref.read(staffServiceProvider).getStaff(orgId);
  // Filtrar solo managers activos
  return staff
      .where(
        (perfil) =>
            perfil.rol == RolUsuario.manager &&
            perfil.activo == true &&
            perfil.eliminado != true,
      )
      .toList();
});

// ============================================================================
// Provider para obtener notificaciones del usuario
// ============================================================================
final orgAdminNotificationsProvider =
    FutureProvider.autoDispose<List<Notificacion>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Usuario no autenticado');
  
  return ref
      .read(complianceServiceProvider)
      .getNotifications(userId);
});

// ============================================================================
// Provider para obtener conteo de notificaciones no leídas
// ============================================================================
final unreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 0;
  
  return ref
      .read(complianceServiceProvider)
      .getUnreadNotificationsCount(userId);
});

// ============================================================================
// Provider para obtener logs de auditoría (solo auditor/super_admin)
// ============================================================================
final orgAdminAuditLogProvider =
    FutureProvider.autoDispose<List<AuditoriaLog>>((ref) async {
  final orgId = await _requireOrgId(ref);
  
  return ref
      .read(complianceServiceProvider)
      .getAuditLog(orgId: orgId, limit: 100);
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
      () => ref.read(complianceServiceProvider).resolveAlert(
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

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, void>(
      AlertsController.new,
    );

