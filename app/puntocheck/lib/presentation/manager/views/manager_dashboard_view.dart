import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerDashboardView extends StatelessWidget {
  const ManagerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: const [
              Expanded(
                child: AdminStatCard(
                  label: 'Presentes hoy',
                  value: '--',
                  hint: 'Equipo en turno',
                  icon: Icons.check_circle_outline,
                  color: AppColors.successGreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Tardanzas',
                  value: '--',
                  hint: 'Supera tolerancia',
                  icon: Icons.schedule_outlined,
                  color: AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: AdminStatCard(
                  label: 'Permisos pendientes',
                  value: '--',
                  hint: 'Aprobaciones del equipo',
                  icon: Icons.mail_outline,
                  color: AppColors.primaryRed,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Horas extra',
                  value: '--',
                  hint: 'Acumulado semanal',
                  icon: Icons.trending_up,
                  color: AppColors.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Turnos de hoy',
            child: EmptyState(
              title: 'Sin turnos cargados',
              message: 'Configura los turnos de tu equipo para monitorear asistencia.',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          const SectionCard(
            title: 'Alertas de cumplimiento',
            child: EmptyState(
              title: 'Sin alertas',
              message: 'Verás aquí las incidencias legales o faltas de tu equipo.',
              icon: Icons.gavel_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
