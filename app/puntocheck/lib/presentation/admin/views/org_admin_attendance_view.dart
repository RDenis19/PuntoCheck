import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminAttendanceView extends ConsumerWidget {
  const OrgAdminAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final attendanceAsync = ref.watch(
      orgAdminAttendanceProvider(
        OrgAdminAttendanceFilter(
          startDate: startOfDay,
          endDate: now,
          limit: 100,
        ),
      ),
    );

    return attendanceAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const _EmptyState(
            icon: Icons.access_time_outlined,
            text: 'No hay marcas de asistencia registradas.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = logs[index];
            return _AttendanceTile(item: item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error cargando asistencia: $e')),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final RegistrosAsistencia item;

  const _AttendanceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final time =
        '${item.fechaHoraMarcacion.hour.toString().padLeft(2, '0')}:${item.fechaHoraMarcacion.minute.toString().padLeft(2, '0')}';
    final inside = item.estaDentroGeocerca ?? true;
    final legal = item.esValidoLegalmente ?? true;

    Color badgeColor;
    String badgeText;
    if (!inside) {
      badgeColor = AppColors.warningOrange;
      badgeText = 'Fuera de geocerca';
    } else if (!legal) {
      badgeColor = AppColors.errorRed;
      badgeText = 'Revisar';
    } else {
      badgeColor = AppColors.successGreen;
      badgeText = 'OK';
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: badgeColor.withValues(alpha: 0.15),
        child: Icon(
          Icons.access_time,
          color: badgeColor,
        ),
      ),
      title: Text(
        '${item.tipoRegistro ?? "Marca"} - $time',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('Empleado: ${item.perfilId}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          badgeText,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.neutral500),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
