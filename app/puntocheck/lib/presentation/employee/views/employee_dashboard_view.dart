import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeDashboardView extends StatelessWidget {
  const EmployeeDashboardView({super.key});

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
                  label: 'Estado de turno',
                  value: '—',
                  hint: 'Entrada/Salida pendiente',
                  icon: Icons.fingerprint,
                  color: AppColors.primaryRed,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Horas extra',
                  value: '—',
                  hint: 'Acumulado semanal',
                  icon: Icons.trending_up,
                  color: AppColors.infoBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: AdminStatCard(
                  label: 'Permisos',
                  value: '—',
                  hint: 'Pendientes/Activos',
                  icon: Icons.mail_outline,
                  color: AppColors.successGreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Alertas',
                  value: '—',
                  hint: 'Tardanzas o faltas',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Próximos turnos',
            child: EmptyState(
              title: 'Sin turnos cargados',
              message: 'Verás aquí tus próximos turnos asignados.',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          const SectionCard(
            title: 'Notificaciones',
            child: EmptyState(
              title: 'Sin notificaciones',
              message: 'Las alertas de asistencia y permisos se mostrarán aquí.',
              icon: Icons.notifications_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
