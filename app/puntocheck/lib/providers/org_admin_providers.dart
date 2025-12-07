import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/pagos_suscripciones.dart';
import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

// ============================================================================
// Helpers
// ============================================================================
String _requireOrgId(Ref ref) {
  final profile = ref.read(profileProvider).asData?.value;
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
      final orgId = _requireOrgId(ref);
      return ref.read(organizationServiceProvider).getMyOrganization(orgId);
    });

final orgAdminStaffProvider = FutureProvider.family<List<Perfiles>,
    OrgAdminPeopleFilter>((ref, filter) async {
  final orgId = _requireOrgId(ref);
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
      final orgId = _requireOrgId(ref);
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
      final orgId = _requireOrgId(ref);
      return ref
          .read(paymentsServiceProvider)
          .listPayments(orgId: orgId, estado: EstadoPago.pendiente);
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
      final orgId = _requireOrgId(ref);

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
      ref
        ..invalidate(orgAdminPermissionsProvider(true))
        ..invalidate(orgAdminAlertsProvider);
    }
  }
}

final orgAdminPermissionControllerProvider =
    AsyncNotifierProvider<OrgAdminPermissionController, void>(
      OrgAdminPermissionController.new,
    );
