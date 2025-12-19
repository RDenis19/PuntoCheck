import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/auditor_attendance_entry.dart';
import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/perfiles.dart';
import '../models/sucursales.dart';
import '../services/auditor_service.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

// ============================================================================
// Servicio del rol auditor
// ============================================================================
final auditorServiceProvider = Provider<AuditorService>((ref) {
  return AuditorService.instance;
});

final auditorTabIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// Perfil / organización del auditor
// ============================================================================
final auditorProfileProvider = FutureProvider<Perfiles>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) throw Exception('No se pudo cargar el perfil');
  return profile;
});

Future<String> _requireAuditorOrgId(Ref ref) async {
  final profile = await ref.watch(auditorProfileProvider.future);
  if (profile.rol != RolUsuario.auditor) {
    throw Exception('Acceso denegado: rol no autorizado.');
  }
  final orgId = profile.organizacionId;
  if (orgId == null || orgId.isEmpty) {
    throw Exception('No tienes organización asignada.');
  }
  return orgId;
}

/// Helper reutilizable para obtener el `organizacion_id` del Auditor.
Future<String> requireAuditorOrgId(Ref ref) => _requireAuditorOrgId(ref);

final auditorOrganizationProvider = FutureProvider<Organizaciones>((ref) async {
  final orgId = await _requireAuditorOrgId(ref);
  return ref.read(organizationServiceProvider).getMyOrganization(orgId);
});

final auditorBranchesProvider =
    FutureProvider.autoDispose<List<Sucursales>>((ref) async {
      final orgId = await _requireAuditorOrgId(ref);
      return ref
          .read(auditorServiceProvider)
          .getOrganizationBranches(orgId: orgId);
    });

// ============================================================================
// Asistencia (auditor)
// ============================================================================
class AuditorAttendanceFilter {
  final DateTimeRange? dateRange;
  final String? branchId;
  final String query;
  final bool onlyGeofenceIssues;
  final bool onlyMockLocation;

  const AuditorAttendanceFilter({
    this.dateRange,
    this.branchId,
    this.query = '',
    this.onlyGeofenceIssues = false,
    this.onlyMockLocation = false,
  });

  AuditorAttendanceFilter copyWith({
    DateTimeRange? dateRange,
    bool dateRangeToNull = false,
    String? branchId,
    bool branchIdToNull = false,
    String? query,
    bool? onlyGeofenceIssues,
    bool? onlyMockLocation,
  }) {
    return AuditorAttendanceFilter(
      dateRange: dateRangeToNull ? null : (dateRange ?? this.dateRange),
      branchId: branchIdToNull ? null : (branchId ?? this.branchId),
      query: query ?? this.query,
      onlyGeofenceIssues: onlyGeofenceIssues ?? this.onlyGeofenceIssues,
      onlyMockLocation: onlyMockLocation ?? this.onlyMockLocation,
    );
  }

  static AuditorAttendanceFilter initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 6),
    );
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return AuditorAttendanceFilter(dateRange: DateTimeRange(start: start, end: end));
  }

  @override
  bool operator ==(Object other) {
    return other is AuditorAttendanceFilter &&
        other.branchId == branchId &&
        other.query == query &&
        other.onlyGeofenceIssues == onlyGeofenceIssues &&
        other.onlyMockLocation == onlyMockLocation &&
        other.dateRange?.start == dateRange?.start &&
        other.dateRange?.end == dateRange?.end;
  }

  @override
  int get hashCode => Object.hash(
        dateRange?.start,
        dateRange?.end,
        branchId,
        query,
        onlyGeofenceIssues,
        onlyMockLocation,
      );
}

final auditorAttendanceFilterProvider = StateProvider<AuditorAttendanceFilter>((ref) {
  return AuditorAttendanceFilter.initial();
});

final auditorAttendanceProvider =
    FutureProvider.autoDispose<List<AuditorAttendanceEntry>>((ref) async {
      final filter = ref.watch(auditorAttendanceFilterProvider);
      final orgId = await _requireAuditorOrgId(ref);

      DateTime? start = filter.dateRange?.start;
      DateTime? end = filter.dateRange?.end;
      if (start != null) start = DateTime(start.year, start.month, start.day);
      if (end != null) {
        end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      }

      return ref.read(auditorServiceProvider).getAttendanceRecords(
            orgId: orgId,
            startDate: start,
            endDate: end,
            branchId: filter.branchId,
            employeeQuery: filter.query,
            onlyGeofenceIssues: filter.onlyGeofenceIssues,
            onlyMockLocation: filter.onlyMockLocation,
            limit: 300,
          );
    });

final auditorAttendanceRecordProvider = FutureProvider.autoDispose
    .family<AuditorAttendanceEntry, String>((ref, recordId) async {
      return ref.read(auditorServiceProvider).getAttendanceRecordById(recordId);
    });

/// Resuelve una URL de evidencia. Si la DB guarda un path (p.ej. `uid/archivo.jpg`),
/// se genera una signed URL contra el bucket `evidencias`.
final auditorEvidenceUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, raw) async {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }

      // Signed URL por 1 hora.
      final signed = await ref
          .read(storageServiceProvider)
          .getSignedUrl('evidencias', trimmed, expiresIn: 60 * 60);
      return signed.isNotEmpty ? signed : trimmed;
    });

class AuditorAttendanceNotesController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> updateNotes({
    required String recordId,
    required String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(auditorServiceProvider)
          .updateAttendanceNotes(recordId: recordId, notes: notes),
    );

    if (!state.hasError) {
      ref
        ..invalidate(auditorAttendanceProvider)
        ..invalidate(auditorAttendanceRecordProvider(recordId));
    }
  }
}

final auditorAttendanceNotesControllerProvider =
    AsyncNotifierProvider<AuditorAttendanceNotesController, void>(
  AuditorAttendanceNotesController.new,
);

// ============================================================================
// Alertas (auditor)
// ============================================================================
class AuditorAlertsFilter {
  final String query;
  final String? status;
  final String? branchId;
  final GravedadAlerta? severity;
  final String? typeQuery;

  const AuditorAlertsFilter({
    this.query = '',
    this.status,
    this.branchId,
    this.severity,
    this.typeQuery,
  });

  AuditorAlertsFilter copyWith({
    String? query,
    String? status,
    bool statusToNull = false,
    String? branchId,
    bool branchIdToNull = false,
    GravedadAlerta? severity,
    bool severityToNull = false,
    String? typeQuery,
    bool typeQueryToNull = false,
  }) {
    return AuditorAlertsFilter(
      query: query ?? this.query,
      status: statusToNull ? null : (status ?? this.status),
      branchId: branchIdToNull ? null : (branchId ?? this.branchId),
      severity: severityToNull ? null : (severity ?? this.severity),
      typeQuery: typeQueryToNull ? null : (typeQuery ?? this.typeQuery),
    );
  }

  static AuditorAlertsFilter initial() => const AuditorAlertsFilter();

  @override
  bool operator ==(Object other) {
    return other is AuditorAlertsFilter &&
        other.query == query &&
        other.status == status &&
        other.branchId == branchId &&
        other.severity == severity &&
        other.typeQuery == typeQuery;
  }

  @override
  int get hashCode => Object.hash(query, status, branchId, severity, typeQuery);
}

final auditorAlertsFilterProvider = StateProvider<AuditorAlertsFilter>((ref) {
  return AuditorAlertsFilter.initial();
});

final auditorAlertsProvider =
    FutureProvider.autoDispose<List<AlertasCumplimiento>>((ref) async {
      final orgId = await _requireAuditorOrgId(ref);
      final filter = ref.watch(auditorAlertsFilterProvider);

      return ref.read(auditorServiceProvider).getComplianceAlerts(
            orgId: orgId,
            status: filter.status,
            employeeQuery: filter.query,
            branchId: filter.branchId,
            severity: filter.severity,
            typeQuery: filter.typeQuery,
            limit: 500,
          );
    });

class AuditorAlertsController extends AsyncNotifier<void> {
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
      ref.invalidate(auditorAlertsProvider);
    }
  }
}

final auditorAlertsControllerProvider =
    AsyncNotifierProvider<AuditorAlertsController, void>(
  AuditorAlertsController.new,
);
