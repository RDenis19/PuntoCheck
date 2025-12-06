import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Métricas clave
          Row(
            children: const [
              Expanded(
                child: AdminStatCard(
                  label: 'Asistencia hoy',
                  value: '—',
                  hint: 'Presentes / programados',
                  icon: Icons.access_time,
                  color: AppColors.primaryRed,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Tardanzas',
                  value: '—',
                  hint: 'Dentro de tolerancia',
                  icon: Icons.warning_amber_rounded,
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
                  label: 'Horas extra',
                  value: '—',
                  hint: 'Acumulado semana',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.infoBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Permisos pendientes',
                  value: '—',
                  hint: 'Esperando aprobación',
                  icon: Icons.mail_outline,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alertas legales LOE
          const SectionCard(
            title: 'Alertas legales (LOE)',
            child: EmptyState(
              title: 'Sin alertas registradas',
              message:
                  'Cuando haya jornadas excesivas o descansos insuficientes, las verás aquí.',
              icon: Icons.gavel_outlined,
            ),
          ),

          // Permisos y licencias
          const SectionCard(
            title: 'Permisos y licencias',
            child: EmptyState(
              title: 'No hay solicitudes pendientes',
              message:
                  'Las solicitudes con documentación aparecerán aquí para aprobación.',
              icon: Icons.description_outlined,
            ),
          ),

          // Configuración operativa
          const SectionCard(
            title: 'Configuración operativa',
            child: EmptyState(
              title: 'Configura geocercas, tolerancias y descansos',
              message:
                  'Ajusta los parámetros de jornada y descansos para cumplir la LOE.',
              icon: Icons.settings_suggest_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
