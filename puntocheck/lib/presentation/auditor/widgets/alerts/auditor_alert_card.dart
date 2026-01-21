import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_constants.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAlertCard extends StatelessWidget {
  final AlertasCumplimiento alert;
  final String? branchName;
  final VoidCallback onTap;
  final bool isNew;

  const AuditorAlertCard({
    super.key,
    required this.alert,
    required this.branchName,
    required this.onTap,
    this.isNew = false,
  });

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final severity = AuditorAlertConstants.severityColor(alert.gravedad);
    final statusColor = AuditorAlertConstants.statusColor(alert.estado);
    final employee = alert.empleadoNombreCompleto ?? 'Sin empleado';
    final created = alert.fechaDeteccion;
    final subtitle = [
      if (branchName != null && branchName!.trim().isNotEmpty)
        branchName!.trim(),
      if (created != null) _fmt.format(created),
    ].join(' · ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isNew
              ? AppColors.primaryRed
              : severity.withValues(alpha: 0.28),
          width: isNew ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: severity.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield_rounded, color: severity),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isNew) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NUEVA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                _humanize(alert.tipoIncumplimiento),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral700,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Pill(
                        label: alert.gravedad?.value ?? 'advertencia',
                        color: severity,
                      ),
                      const SizedBox(height: 8),
                      _Pill(
                        label: AuditorAlertConstants.statusLabel(alert.estado),
                        color: statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

String _humanize(String text) {
  if (text.isEmpty) return text;
  final replaced = text.replaceAll('_', ' ');
  return replaced[0].toUpperCase() + replaced.substring(1).toLowerCase();
}
