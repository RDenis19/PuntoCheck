import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/auditor_attendance_entry.dart';
import 'package:puntocheck/services/attendance_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAttendanceRecordCard extends StatelessWidget {
  final AuditorAttendanceEntry entry;
  final VoidCallback? onTap;

  const AuditorAttendanceRecordCard({super.key, required this.entry, this.onTap});

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final r = entry.record;
    final type = (r.tipoRegistro ?? '').trim();
    final typeLabel = type.isEmpty ? '—' : AttendanceHelper.getTypeLabel(type);
    final color = _typeColor(type);

    final geofenceOk = r.estaDentroGeocerca;
    final isMock = r.esMockLocation == true;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                child: Icon(_typeIcon(type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.perfilNombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt.format(r.fechaHoraMarcacion)} · $typeLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.sucursalNombre ?? 'Sin sucursal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  _StatusDot(
                    color: geofenceOk == null
                        ? AppColors.neutral500
                        : (geofenceOk
                            ? AppColors.successGreen
                            : AppColors.errorRed),
                    icon: geofenceOk == null
                        ? Icons.location_searching
                        : (geofenceOk
                            ? Icons.location_on
                            : Icons.location_off),
                    tooltip: geofenceOk == null
                        ? 'Geocerca: desconocido'
                        : (geofenceOk
                            ? 'Dentro de geocerca'
                            : 'Fuera de geocerca'),
                  ),
                  const SizedBox(height: 8),
                  _StatusDot(
                    color: isMock ? AppColors.warningOrange : AppColors.neutral300,
                    icon: isMock ? Icons.gps_off : Icons.gps_fixed,
                    tooltip: isMock ? 'Mock location detectado' : 'GPS OK',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'entrada':
        return Icons.login;
      case 'salida':
        return Icons.logout;
      case 'inicio_break':
        return Icons.coffee_outlined;
      case 'fin_break':
        return Icons.coffee;
      default:
        return Icons.access_time;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'entrada':
        return AppColors.successGreen;
      case 'salida':
        return AppColors.primaryRed;
      case 'inicio_break':
      case 'fin_break':
        return AppColors.warningOrange;
      default:
        return AppColors.neutral600;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tooltip;

  const _StatusDot({
    required this.color,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
