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
          final planNames = {
            for (final plan in data.plans) plan.id: plan.nombre,
          };

          return RefreshIndicator(
            onRefresh: () => ref.refresh(superAdminDashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: [
                const _SectionTitle('Resumen general'),
                const SizedBox(height: 12),
                _BillingCard(monthlyRevenue: data.monthlyRevenue),

                const SizedBox(height: 20),
                const _SectionTitle('Información de organizaciones'),
                const SizedBox(height: 12),
                _StatusGrid(
                  total: data.totalOrganizations,
                  active: data.activeOrganizations,
                  trial: data.trialOrganizations,
                ),

                const SizedBox(height: 24),
                _RecentOrgsSection(
                  data: data,
                  planNames: planNames,
                  onTapOrg: (orgId) =>
                      context.push('${AppRoutes.superAdminHome}/org/$orgId'),
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
          message: error.toString(),
          onRetry: () => ref.refresh(superAdminDashboardProvider),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               SECTION TITLE                                 */
/* -------------------------------------------------------------------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.neutral900,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               BILLING CARD                                  */
/* -------------------------------------------------------------------------- */

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.monthlyRevenue});

  final double monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.attach_money,
              color: AppColors.primaryRed,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresos del mes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${monthlyRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'USD',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               STATUS GRID                                   */
/* -------------------------------------------------------------------------- */

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(
              label: 'Total',
              value: total,
              color: AppColors.primaryRed,
              icon: Icons.apartment_rounded,
              width: itemWidth,
            ),
            _StatCard(
              label: 'Activas',
              value: active,
              color: Colors.green,
              icon: Icons.verified_outlined,
              width: itemWidth,
            ),
            _StatCard(
              label: 'Prueba',
              value: trial,
              color: Colors.orange,
              icon: Icons.timer_outlined,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.width,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           RECENT ORGANIZATIONS                               */
/* -------------------------------------------------------------------------- */

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
        message: 'Cuando existan cuentas nuevas se listarán aquí.',
        icon: Icons.business_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Organizaciones recientes'),
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

/* -------------------------------------------------------------------------- */
/*                                   ERROR                                     */
/* -------------------------------------------------------------------------- */

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
            const Text(
              'No se pudo cargar el dashboard',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 14),
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
