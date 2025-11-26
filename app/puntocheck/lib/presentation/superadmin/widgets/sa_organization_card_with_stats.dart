import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card.dart';

/// Widget wrapper que obtiene las estadisticas de una organizacion
/// y las pasa a SaOrganizationCard
class SaOrganizationCardWithStats extends ConsumerWidget {
  const SaOrganizationCardWithStats({
    super.key,
    required this.organization,
    required this.onTap,
  });

  final Organization organization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      organizationDashboardStatsProvider(organization.id),
    );

    return statsAsync.when(
      data: (stats) => SaOrganizationCard(
        organization: organization,
        onTap: onTap,
        totalEmployees: stats.totalEmployees,
        activeToday: stats.activeToday,
        attendanceAverage: stats.attendanceAverage,
      ),
      loading: () => SaOrganizationCard(
        organization: organization,
        onTap: onTap,
        isLoading: true,
      ),
      error: (_, __) => SaOrganizationCard(
        organization: organization,
        onTap: onTap,
        hasStatsError: true,
      ),
    );
  }
}
