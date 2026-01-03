import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
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

    String? branchNameFor(String? branchId) {
      final id = (branchId ?? '').trim();
      if (id.isEmpty) return null;
      final branches = branchesAsync.valueOrNull ?? const [];
      final match = branches.where((b) => b.id == id).toList();
      return match.isEmpty ? null : match.first.nombre;
    }

    // Removed SafeArea to fix gap under header
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: _RedStatCard(
                label: 'Alertas abiertas',
                value: metricValue(metrics?.openAlerts),
                icon: Icons.report_gmailerrorred_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RedStatCard(
                label: 'Permisos pendientes',
                value: metricValue(metrics?.pendingPermissions),
                icon: Icons.event_note_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RedStatCard(
          label: 'Marcas observadas hoy',
          value: metricValue(metrics?.attendanceToday),
          icon: Icons.fingerprint_rounded,
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
              icon: Icons.error_outline_rounded,
              onAction: () => ref.invalidate(auditorDashboardRecentFindingsProvider),
              actionLabel: 'Reintentar',
            ),
            data: (alerts) {
              if (alerts.isEmpty) {
                return const EmptyState(
                  title: 'Sin hallazgos',
                  message: 'Cuando existan alertas aparecerán aquí.',
                  icon: Icons.report_gmailerrorred_rounded,
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
                      icon: const Icon(Icons.open_in_new_rounded),
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
              icon: Icons.error_outline_rounded,
              onAction: () => ref.invalidate(auditorAuditLogRecentProvider),
              actionLabel: 'Reintentar',
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return const EmptyState(
                  title: 'Sin eventos',
                  message: 'Aquí verás acciones sensibles con trazabilidad completa.',
                  icon: Icons.history_rounded,
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
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Ver todo'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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

    final changed = await showModalBottomSheet<bool>(
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

    if (changed == true) {
      ref.invalidate(auditorDashboardMetricsProvider);
      ref.invalidate(auditorDashboardRecentFindingsProvider);
    }
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

// ============================================================================
// WIDGET LOCALS
// ============================================================================

/// Tarjeta de estadística roja con ícono blanco y texto blanco,
/// estilo "block" uniforme.
class _RedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RedStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura fija para uniformidad ("del mismo porte")
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icono y Valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

