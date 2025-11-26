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
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDark,
            AppColors.black.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                      AppColors.primaryRed.withValues(alpha: 0.12),
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
                          color: AppColors.primaryRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Estadisticas globales',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Resumen vivo del ecosistema PuntoCheck',
                            style: TextStyle(
                              color: Colors.white70,
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
    final cards = [
      SaKpiCard(
        label: 'Organizaciones',
        value: '$totalOrgs',
        icon: Icons.apartment_outlined,
        color: AppColors.primaryRed,
      ),
      SaKpiCard(
        label: 'Usuarios totales',
        value: '$totalUsers',
        icon: Icons.people_outline,
        color: AppColors.successGreen,
      ),
      SaKpiCard(
        label: 'Planes activos',
        value: '$activePlans',
        icon: Icons.flash_on_outlined,
        color: AppColors.warningOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final cardWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
