import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_kpi_card.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Seccion de estadisticas globales del Super Admin.
/// Muestra KPIs principales: organizaciones, usuarios y planes activos.
class SaStatsSection extends StatelessWidget {
  const SaStatsSection({
    super.key,
    required this.totalOrgs,
    required this.totalUsers,
    required this.activePlans,
    this.isLoading = false,
  });

  final int totalOrgs;
  final int totalUsers;
  final int activePlans;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.infoBlue.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.infoBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estadisticas globales',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Resumen vivo del ecosistema PuntoCheck',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    _buildLoadingState()
                  else
                    _buildKpiCards(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SaKpiCard(
            label: 'Orgs',
            value: '$totalOrgs',
            icon: Icons.apartment_outlined,
            color: AppColors.infoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SaKpiCard(
            label: 'Usuarios',
            value: '$totalUsers',
            icon: Icons.people_outline,
            color: AppColors.infoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SaKpiCard(
            label: 'Planes',
            value: '$activePlans',
            icon: Icons.flash_on_outlined,
            color: AppColors.infoBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
