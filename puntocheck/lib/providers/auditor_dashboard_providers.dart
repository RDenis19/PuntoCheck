import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import 'auditor_providers.dart';

class AuditorDashboardMetrics {
  final int? openAlerts;
  final int? pendingPermissions;
  final int? attendanceToday;

  const AuditorDashboardMetrics({
    required this.openAlerts,
    required this.pendingPermissions,
    required this.attendanceToday,
  });
}

Future<int?> _safeCount(Future<int> Function() loader) async {
  try {
    return await loader();
  } catch (_) {
    return null;
  }
}

final auditorDashboardMetricsProvider =
    StreamProvider.autoDispose<AuditorDashboardMetrics>((ref) async* {
  final orgId = await requireAuditorOrgId(ref);
  final svc = ref.read(auditorServiceProvider);

  Future<AuditorDashboardMetrics> fetchData() async {
    final openAlerts = await _safeCount(
      () => svc.countComplianceAlerts(
        orgId: orgId,
        statuses: const ['pendiente', 'en_revision'],
      ),
    );

    final pendingPermissions = await _safeCount(
      () => svc.countPendingLeaveRequests(orgId: orgId),
    );

    final attendanceToday = await _safeCount(
      () => svc.countAttendanceToday(orgId: orgId),
    );

    return AuditorDashboardMetrics(
      openAlerts: openAlerts,
      pendingPermissions: pendingPermissions,
      attendanceToday: attendanceToday,
    );
  }

  // Emit initial value
  yield await fetchData();

  // Polling every 15s
  final timer = Stream.periodic(const Duration(seconds: 15), (i) => i);
  await for (final _ in timer) {
     yield await fetchData();
  }
});

final auditorDashboardRecentFindingsProvider =
    FutureProvider.autoDispose<List<AlertasCumplimiento>>((ref) async {
  final orgId = await requireAuditorOrgId(ref);
  return ref.read(auditorServiceProvider).getComplianceAlerts(
        orgId: orgId,
        limit: 3,
      );
});

