import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_stats_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Sección de estadísticas de asistencia en grid
class AttendanceStatsSection extends StatelessWidget {
  final int total;
  final int valid;
  final int outsideGeofence;
  final int errors;

  const AttendanceStatsSection({
    super.key,
    required this.total,
    required this.valid,
    required this.outsideGeofence,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Resumen de Hoy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.neutral900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            AttendanceStatsCard(
              label: 'Total Marcas',
              value: '$total',
              icon: Icons.calendar_today_rounded,
              color: AppColors.neutral900,
            ),
            AttendanceStatsCard(
              label: 'Correctas',
              value: '$valid',
              icon: Icons.check_circle_rounded,
              color: AppColors.successGreen,
              subtitle: 'Dentro de geocerca',
            ),
            AttendanceStatsCard(
              label: 'Fuera Geocerca',
              value: '$outsideGeofence',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warningOrange,
              subtitle: 'Requiere revisión',
            ),
            AttendanceStatsCard(
              label: 'Con Errores',
              value: '$errors',
              icon: Icons.error_rounded,
              color: AppColors.errorRed,
              subtitle: 'No válidos',
            ),
          ],
        ),
      ],
    );
  }
}
