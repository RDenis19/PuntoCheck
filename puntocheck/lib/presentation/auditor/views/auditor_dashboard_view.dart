import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_card.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_detail_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/audit/auditor_audit_log_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/auditor_audit_providers.dart';
import 'package:puntocheck/providers/auditor_dashboard_providers.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorDashboardView extends ConsumerWidget {
  const AuditorDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(auditorDashboardMetricsProvider);
    final findingsAsync = ref.watch(auditorDashboardRecentFindingsProvider);
    final auditAsync = ref.watch(auditorAuditLogRecentProvider);
    final branchesAsync = ref.watch(auditorBranchesProvider);

    final metrics = metricsAsync.valueOrNull;

    String metricValue(int? v) {
      if (v != null) return '$v';
      return metricsAsync.isLoading ? '...' : '—';
    }

    String? metricHint(int? v, String hint) {
      if (v != null) return hint;
      return metricsAsync.isLoading ? 'Cargando...' : 'Sin permisos (RLS) o error';
    }

    String? branchNameFor(String? branchId) {
      final id = (branchId ?? '').trim();
      if (id.isEmpty) return null;
      final branches = branchesAsync.valueOrNull ?? const [];
      final match = branches.where((b) => b.id == id).toList();
      return match.isEmpty ? null : match.first.nombre;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Alertas abiertas',
                  value: metricValue(metrics?.openAlerts),
                  hint: metricHint(metrics?.openAlerts, 'Pendientes / en revisión'),
                  icon: Icons.report_gmailerrorred_outlined,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Permisos pendientes',
                  value: metricValue(metrics?.pendingPermissions),
                  hint: metricHint(metrics?.pendingPermissions, 'Solicitudes por revisar'),
                  icon: Icons.event_note_outlined,
                  color: AppColors.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminStatCard(
            label: 'Marcas observadas hoy',
            value: metricValue(metrics?.attendanceToday),
            hint: metricHint(metrics?.attendanceToday, 'Registros de asistencia (hoy)'),
            icon: Icons.fingerprint_outlined,
            color: AppColors.neutral700,
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Hallazgos recientes',
            child: findingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
              error: (e, _) => EmptyState(
                title: 'No se pudo cargar',
                message: '$e',
                icon: Icons.error_outline,
                onAction: () => ref.invalidate(auditorDashboardRecentFindingsProvider),
                actionLabel: 'Reintentar',
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const EmptyState(
                    title: 'Sin hallazgos',
                    message: 'Cuando existan alertas aparecerán aquí.',
                    icon: Icons.report_gmailerrorred_outlined,
                  );
                }

                return Column(
                  children: [
                    for (final a in alerts) ...[
                      AuditorAlertCard(
                        alert: a,
                        branchName: branchNameFor(a.empleadoSucursalId),
                        onTap: () => _openAlertDetail(
                          context,
                          ref,
                          alert: a,
                          branchName: branchNameFor(a.empleadoSucursalId),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(auditorTabIndexProvider.notifier).state = 3,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver todas'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SectionCard(
            title: 'Auditoría del sistema',
            child: auditAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
              error: (e, _) => EmptyState(
                title: 'No se pudo cargar',
                message: '$e',
                icon: Icons.error_outline,
                onAction: () => ref.invalidate(auditorAuditLogRecentProvider),
                actionLabel: 'Reintentar',
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return const EmptyState(
                    title: 'Sin eventos',
                    message: 'Aquí verás acciones sensibles con trazabilidad completa.',
                    icon: Icons.history,
                  );
                }

                return Column(
                  children: [
                    for (final l in logs) ...[
                      AuditorAuditLogCard(
                        log: l,
                        onTap: () => context.push('${AppRoutes.auditorHome}/auditoria'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('${AppRoutes.auditorHome}/auditoria'),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver todo'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAlertDetail(
    BuildContext context,
    WidgetRef ref, {
    required AlertasCumplimiento alert,
    required String? branchName,
  }) async {
    final recordId = _tryExtractAttendanceRecordId(alert.detalleTecnico);
    final controller = ref.read(auditorAlertsControllerProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditorAlertDetailSheet(
        alert: alert,
        branchName: branchName,
        recordLabel: recordId == null ? 'Ver evidencia' : 'Ir a marca',
        onOpenRecord: recordId == null
            ? null
            : () {
                Navigator.pop(context);
                context.push('${AppRoutes.auditorHome}/asistencia/$recordId');
              },
        onOpenEmployeeAttendance: alert.empleadoId == null
            ? null
            : () {
                final q = (alert.empleadoCedula ?? '').trim().isNotEmpty
                    ? alert.empleadoCedula!.trim()
                    : (alert.empleadoNombreCompleto ?? '').trim();
                ref.read(auditorAttendanceFilterProvider.notifier).state =
                    AuditorAttendanceFilter.initial().copyWith(
                      query: q,
                      branchId: alert.empleadoSucursalId,
                    );
                ref.read(auditorTabIndexProvider.notifier).state = 1;
                Navigator.pop(context);
                context.go(AppRoutes.auditorHome);
              },
        onSave: ({required status, required justification}) => controller.resolve(
          alertId: alert.id,
          newStatus: status,
          justification: justification,
        ),
      ),
    );
  }
}

String? _tryExtractAttendanceRecordId(Map<String, dynamic>? json) {
  if (json == null) return null;
  const candidates = [
    'registro_asistencia_id',
    'registro_id',
    'registros_asistencia_id',
    'attendance_id',
  ];

  bool looksLikeUuid(String s) {
    final t = s.trim();
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(t);
  }

  for (final key in candidates) {
    final v = json[key];
    if (v is String && looksLikeUuid(v)) return v.trim();
  }

  for (final v in json.values) {
    if (v is String && looksLikeUuid(v)) return v.trim();
  }

  return null;
}

