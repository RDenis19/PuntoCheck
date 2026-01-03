import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_notifications_action.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeComplianceAlertsView extends ConsumerStatefulWidget {
  const EmployeeComplianceAlertsView({super.key});

  @override
  ConsumerState<EmployeeComplianceAlertsView> createState() =>
      _EmployeeComplianceAlertsViewState();
}

class _EmployeeComplianceAlertsViewState
    extends ConsumerState<EmployeeComplianceAlertsView> {
  _ComplianceStatusFilter _statusFilter = _ComplianceStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(employeeComplianceAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Alertas de cumplimiento'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          const EmployeeNotificationsAction(),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => ref.invalidate(employeeComplianceAlertsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(employeeComplianceAlertsProvider),
        ),
        data: (alerts) {
          final filtered = _applyStatusFilter(alerts, _statusFilter);
          final pendingCount =
              alerts.where((a) => (a.estado ?? '').toLowerCase() == 'pendiente').length;
          final fmt = DateFormat('dd/MM/yyyy HH:mm');

          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () async {
              ref.invalidate(employeeComplianceAlertsProvider);
              await ref.read(employeeComplianceAlertsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  total: alerts.length,
                  pending: pendingCount,
                  filter: _statusFilter,
                  onFilterChanged: (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _EmptyState()
                else
                  ...filtered.map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertTile(
                        alert: alert,
                        dateLabel: alert.fechaDeteccion != null
                            ? fmt.format(alert.fechaDeteccion!.toLocal())
                            : null,
                        onTap: () => _openDetail(context, alert),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Estas alertas son informativas. Si tienes dudas, comunícate con tu Manager o RRHH.',
                  style: TextStyle(color: AppColors.neutral600, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AlertasCumplimiento> _applyStatusFilter(
    List<AlertasCumplimiento> alerts,
    _ComplianceStatusFilter filter,
  ) {
    switch (filter) {
      case _ComplianceStatusFilter.all:
        return alerts;
      case _ComplianceStatusFilter.pending:
        return alerts
            .where((a) => (a.estado ?? '').trim().toLowerCase() == 'pendiente')
            .toList();
    }
  }

  Future<void> _openDetail(BuildContext context, AlertasCumplimiento alert) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) {
        final detail = _formatDetail(alert.detalleTecnico);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: _severityColor(alert.gravedad),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert.tipoIncumplimiento,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: _severityLabel(alert.gravedad),
                        background: _severityColor(alert.gravedad).withValues(alpha: 0.12),
                        foreground: _severityColor(alert.gravedad),
                        icon: Icons.priority_high_rounded,
                      ),
                      _Chip(
                        label: _statusLabel(alert.estado),
                        background:
                            _statusColor(alert.estado).withValues(alpha: 0.12),
                        foreground: _statusColor(alert.estado),
                        icon: Icons.info_outline_rounded,
                      ),
                    ],
                  ),
                  if (alert.fechaDeteccion != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppColors.neutral600),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(alert.fechaDeteccion!.toLocal()),
                          style: const TextStyle(color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Detalle técnico',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Text(
                      detail.isEmpty ? '—' : detail,
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: const BorderSide(color: AppColors.neutral300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDetail(Map<String, dynamic>? detail) {
    if (detail == null || detail.isEmpty) return '';

    String? firstNonEmptyKeyValue(List<String> keys) {
      for (final k in keys) {
        final v = detail[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty && s != 'null') return s;
      }
      return null;
    }

    final description = firstNonEmptyKeyValue(
      const ['descripcion', 'detalle', 'message', 'motivo', 'razon'],
    );

    final encoder = const JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(detail);

    if (description == null || description.isEmpty) return prettyJson;
    return '$description\n\n$prettyJson';
  }

  Color _severityColor(GravedadAlerta? severity) {
    switch (severity ?? GravedadAlerta.leve) {
      case GravedadAlerta.graveLegal:
        return AppColors.errorRed;
      case GravedadAlerta.moderada:
        return AppColors.warningOrange;
      case GravedadAlerta.leve:
        return AppColors.infoBlue;
    }
  }

  String _severityLabel(GravedadAlerta? severity) {
    switch (severity ?? GravedadAlerta.leve) {
      case GravedadAlerta.graveLegal:
        return 'Gravedad alta';
      case GravedadAlerta.moderada:
        return 'Gravedad media';
      case GravedadAlerta.leve:
        return 'Gravedad baja';
    }
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s == 'pendiente') return AppColors.warningOrange;
    if (s == 'revisado') return AppColors.infoBlue;
    if (s == 'justificado' || s == 'cerrado') return AppColors.successGreen;
    if (s == 'rechazado') return AppColors.errorRed;
    return AppColors.neutral600;
  }

  String _statusLabel(String? status) {
    final s = (status ?? '').trim();
    if (s.isEmpty) return 'Estado: —';
    return 'Estado: $s';
  }
}

enum _ComplianceStatusFilter { all, pending }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.pending,
    required this.filter,
    required this.onFilterChanged,
  });

  final int total;
  final int pending;
  final _ComplianceStatusFilter filter;
  final ValueChanged<_ComplianceStatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.neutral700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Resumen',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
              ),
              Text(
                '$pending pendiente${pending == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.warningOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total',
                  value: total.toString(),
                  color: AppColors.neutral700,
                  icon: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Pendientes',
                  value: pending.toString(),
                  color: AppColors.warningOrange,
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: filter == _ComplianceStatusFilter.all,
                onSelected: (_) => onFilterChanged(_ComplianceStatusFilter.all),
              ),
              ChoiceChip(
                label: const Text('Pendientes'),
                selected: filter == _ComplianceStatusFilter.pending,
                onSelected: (_) => onFilterChanged(_ComplianceStatusFilter.pending),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.dateLabel,
    required this.onTap,
  });

  final AlertasCumplimiento alert;
  final String? dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(alert.gravedad);
    final statusColor = _statusColor(alert.estado);
    final status = (alert.estado ?? '').trim();
    final hasDetail = alert.detalleTecnico != null && alert.detalleTecnico!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: severityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.tipoIncumplimiento,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel!,
                        style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: _severityLabel(alert.gravedad),
                          background: severityColor.withValues(alpha: 0.10),
                          foreground: severityColor,
                          icon: Icons.priority_high_rounded,
                        ),
                        _Chip(
                          label: status.isEmpty ? 'Estado: —' : 'Estado: $status',
                          background: statusColor.withValues(alpha: 0.10),
                          foreground: statusColor,
                          icon: Icons.info_outline_rounded,
                        ),
                        if (hasDetail)
                          const _Chip(
                            label: 'Ver detalle',
                            background: AppColors.neutral100,
                            foreground: AppColors.neutral700,
                            icon: Icons.article_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }

  static Color _severityColor(GravedadAlerta? severity) {
    switch (severity ?? GravedadAlerta.leve) {
      case GravedadAlerta.graveLegal:
        return AppColors.errorRed;
      case GravedadAlerta.moderada:
        return AppColors.warningOrange;
      case GravedadAlerta.leve:
        return AppColors.infoBlue;
    }
  }

  static String _severityLabel(GravedadAlerta? severity) {
    switch (severity ?? GravedadAlerta.leve) {
      case GravedadAlerta.graveLegal:
        return 'Alta';
      case GravedadAlerta.moderada:
        return 'Media';
      case GravedadAlerta.leve:
        return 'Baja';
    }
  }

  static Color _statusColor(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s == 'pendiente') return AppColors.warningOrange;
    if (s == 'revisado') return AppColors.infoBlue;
    if (s == 'justificado' || s == 'cerrado') return AppColors.successGreen;
    if (s == 'rechazado') return AppColors.errorRed;
    return AppColors.neutral600;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No tienes alertas de cumplimiento por el momento.',
              style: TextStyle(color: AppColors.neutral700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
