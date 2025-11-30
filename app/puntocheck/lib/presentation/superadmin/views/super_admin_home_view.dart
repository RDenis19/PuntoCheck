import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_header.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card_with_stats.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_section_title.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_stats_section.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista principal del dashboard del Super Admin.
/// Muestra KPIs globales y las ultimas organizaciones creadas.
class SuperAdminHomeView extends ConsumerWidget {
  const SuperAdminHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync =
        ref.watch(organizationsPageProvider(defaultOrganizationsPageRequest));
    final statsAsync = ref.watch(superAdminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(superAdminStatsProvider);
            ref.invalidate(
              organizationsPageProvider(defaultOrganizationsPageRequest),
            );
            ref.invalidate(profileProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SaHeader(),
                statsAsync.when(
                  data: (stats) => SaStatsSection(
                    totalOrgs: _parseStat(stats, 'organizations'),
                    totalUsers: _parseStat(stats, 'users'),
                    activePlans: _parseStat(stats, 'active_plans'),
                  ),
                  loading: () => const SaStatsSection(
                    totalOrgs: 0,
                    totalUsers: 0,
                    activePlans: 0,
                    isLoading: true,
                  ),
                  error: (_, __) => const SaStatsSection(
                    totalOrgs: 0,
                    totalUsers: 0,
                    activePlans: 0,
                  ),
                ),
                SaSectionTitle(
                  title: 'Organizaciones recientes',
                  action: TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.superAdminOrganizaciones),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Ver todas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.primaryRed,
                        ),
                      ],
                    ),
                  ),
                ),
                orgsAsync.when(
                  data: (page) =>
                      _buildOrganizationsList(context, page.items),
                  loading: () => _buildLoadingState(),
                  error: (error, _) => _buildErrorState(error.toString()),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _parseStat(Map<String, dynamic> stats, String key) {
    final value = stats[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildOrganizationsList(
    BuildContext context,
    List<Organization> orgs,
  ) {
    if (orgs.isEmpty) {
      return _buildEmptyState();
    }

    final recent = orgs.take(3).toList();
    return Column(
      children: recent
          .map(
            (org) => SaOrganizationCardWithStats(
              organization: org,
              onTap: () => context.push(
                AppRoutes.superAdminOrganizacionDetalle,
                extra: org,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: AppColors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay organizaciones registradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las organizaciones apareceran aqui cuando se registren.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.primaryRed,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error al cargar organizaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Intenta nuevamente en un momento.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryRed.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: TextStyle(
                    color: AppColors.primaryRed.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
