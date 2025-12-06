import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/super_admin_dashboard.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/superadmin/widgets/organization_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminHomeView extends ConsumerWidget {
  const SuperAdminHomeView({super.key, this.onOpenOrganizations});

  final VoidCallback? onOpenOrganizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);

    return SafeArea(
      child: dashboardAsync.when(
        data: (data) {
          final planNames = {for (final plan in data.plans) plan.id: plan.nombre};
          return RefreshIndicator(
            onRefresh: () => ref.refresh(superAdminDashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionHeader(),
                const SizedBox(height: 12),
                _BillingCard(monthlyRevenue: data.monthlyRevenue),
                const SizedBox(height: 12),
                _StatusGrid(
                  total: data.totalOrganizations,
                  active: data.activeOrganizations,
                  trial: data.trialOrganizations,
                ),
                const SizedBox(height: 18),
                _RecentOrgsSection(
                  data: data,
                  planNames: planNames,
                  onTapOrg: (orgId) => context.push(
                    '${AppRoutes.superAdminHome}/org/$orgId',
                  ),
                ),
                if (onOpenOrganizations != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenOrganizations,
                    icon: const Icon(Icons.business_outlined),
                    label: const Text('Ver todas las organizaciones'),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: '$error',
          onRetry: () => ref.refresh(superAdminDashboardProvider),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Resumen general',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Vision rapida de organizaciones, ingresos y estados de suscripcion.',
          style: TextStyle(color: AppColors.neutral700),
        ),
      ],
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.monthlyRevenue});

  final double monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFF3FB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.attach_money, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresos del mes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${monthlyRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'USD',
            style: TextStyle(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.total,
    required this.active,
    required this.trial,
  });

  final int total;
  final int active;
  final int trial;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.7,
      children: [
        _MiniCard(
          label: 'Total',
          value: total,
          color: const Color(0xFFEFF4FF),
          textColor: const Color(0xFF6366F1),
          icon: Icons.apartment_rounded,
        ),
        _MiniCard(
          label: 'Activas',
          value: active,
          color: const Color(0xFFE8F9F1),
          textColor: const Color(0xFF10B981),
          icon: Icons.verified_outlined,
        ),
        _MiniCard(
          label: 'Prueba',
          value: trial,
          color: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFFB923C),
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrgsSection extends StatelessWidget {
  const _RecentOrgsSection({
    required this.data,
    required this.planNames,
    required this.onTapOrg,
  });

  final SuperAdminDashboardData data;
  final Map<String, String> planNames;
  final void Function(String orgId) onTapOrg;

  @override
  Widget build(BuildContext context) {
    if (data.recentOrganizations.isEmpty) {
      return const EmptyState(
        title: 'Sin organizaciones registradas',
        message: 'Cuando existan cuentas nuevas se listaran aqui.',
        icon: Icons.business_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organizaciones recientes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ultimas empresas registradas o actualizadas en la plataforma.',
          style: TextStyle(color: AppColors.neutral700),
        ),
        const SizedBox(height: 12),
        for (final org in data.recentOrganizations.take(3)) ...[
          OrganizationCard(
            organization: org,
            planName: planNames[org.planId],
            onTap: () => onTapOrg(org.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.neutral700),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el dashboard'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
