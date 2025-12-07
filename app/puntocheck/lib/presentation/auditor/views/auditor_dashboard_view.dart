import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorDashboardView extends StatelessWidget {
  const AuditorDashboardView({super.key});

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
                  label: 'Alertas legales',
                  value: '--',
                  hint: 'Pendientes de revisión',
                  icon: Icons.gavel_outlined,
                  color: AppColors.primaryRed,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Exportes',
                  value: '--',
                  hint: 'Generados este mes',
                  icon: Icons.file_download_outlined,
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
                  label: 'Tardanzas críticas',
                  value: '--',
                  hint: 'Superan tolerancia',
                  icon: Icons.timer_off_outlined,
                  color: AppColors.warningOrange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  label: 'Turnos nocturnos',
                  value: '--',
                  hint: 'Marcados 22:00-06:00',
                  icon: Icons.nights_stay_outlined,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Hallazgos recientes',
            child: EmptyState(
              title: 'Sin hallazgos',
              message: 'Cuando detectes violaciones LOE aparecerán aquí.',
              icon: Icons.report_gmailerrorred_outlined,
            ),
          ),
          const SectionCard(
            title: 'Logs de auditoría',
            child: EmptyState(
              title: 'Sin logs cargados',
              message: 'Conecta la fuente de logs para revisar accesos y eventos.',
              icon: Icons.list_alt_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
