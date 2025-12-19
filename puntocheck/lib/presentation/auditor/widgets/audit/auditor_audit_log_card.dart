import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/auditoria_log.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAuditLogCard extends StatelessWidget {
  final AuditoriaLog log;
  final VoidCallback onTap;

  const AuditorAuditLogCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final icon = _iconForAction(log.accion);
    final color = _colorForAction(log.accion);
    final actorLabel = log.actorNombreCompleto ??
        (log.usuarioResponsableId != null
            ? 'Actor: ${log.usuarioResponsableId!.substring(0, 8)}...'
            : 'Actor: —');

    final table = (log.tablaAfectada ?? '').trim();
    final record = (log.idRegistroAfectado ?? '').trim();
    final meta = [
      if (table.isNotEmpty) 'Tabla: $table',
      if (record.isNotEmpty) 'ID: ${record.length > 8 ? '${record.substring(0, 8)}...' : record}',
    ].join(' · ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.accion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.neutral700,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      log.creadoEn != null ? _fmt.format(log.creadoEn!) : 'Sin fecha',
                      style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: AppColors.neutral600),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForAction(String action) {
    final a = action.toUpperCase();
    if (a.contains('INSERT') || a.contains('CREATE')) return Icons.add_circle_outline;
    if (a.contains('UPDATE') || a.contains('EDIT')) return Icons.edit_outlined;
    if (a.contains('DELETE') || a.contains('REMOVE')) return Icons.delete_outline;
    return Icons.sync_alt;
  }

  static Color _colorForAction(String action) {
    final a = action.toUpperCase();
    if (a.contains('INSERT') || a.contains('CREATE')) return AppColors.successGreen;
    if (a.contains('DELETE') || a.contains('REMOVE')) return AppColors.errorRed;
    if (a.contains('UPDATE') || a.contains('EDIT')) return AppColors.infoBlue;
    return AppColors.neutral600;
  }
}

