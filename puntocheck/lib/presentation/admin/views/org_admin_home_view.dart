import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/models/subscription_state.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/date_utils.dart' as date_utils;
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/home_header.dart';

class OrgAdminHomeView extends ConsumerStatefulWidget {
  const OrgAdminHomeView({super.key});

  @override
  ConsumerState<OrgAdminHomeView> createState() => _OrgAdminHomeViewState();
}

class _OrgAdminHomeViewState extends ConsumerState<OrgAdminHomeView> {
  // Lista de acciones rápidas para el BottomSheet
  List<_QuickActionData> get _quickActions => const [
    _QuickActionData.route(
      icon: Icons.edit_rounded,
      label: 'Editar organización',
      route: AppRoutes.orgAdminEditOrg,
    ),
    _QuickActionData.route(
      icon: Icons.store_mall_directory_outlined,
      label: 'Sucursales',
      route: AppRoutes.orgAdminBranches,
    ),
    _QuickActionData.route(
      icon: Icons.receipt_long_rounded,
      label: 'Pagos y suscripción',
      route: AppRoutes.orgAdminPayments,
    ),
    _QuickActionData.route(
      icon: Icons.shield_rounded,
      label: 'Alertas',
      route: AppRoutes.orgAdminAlerts,
    ),
    _QuickActionData.route(
      icon: Icons.schedule_outlined,
      label: 'Plantillas horarios',
      route: AppRoutes.orgAdminSchedules,
    ),
    _QuickActionData.route(
      icon: Icons.assignment_ind_rounded,
      label: 'Asignaciones',
      route: AppRoutes.orgAdminScheduleAssignments,
    ),
    _QuickActionData.route(
      icon: Icons.access_time_filled,
      label: 'Banco de horas',
      route: AppRoutes.orgAdminHoursBank,
    ),
    _QuickActionData.tab(
      icon: Icons.event_note_outlined,
      label: 'Permisos',
      tabIndex: 3,
    ),
  ];

  void _goToTab(int index) {
    ref.read(orgAdminTabIndexProvider.notifier).state = index;
    if (!mounted) return;
    context.go(AppRoutes.orgAdminHome);
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acciones Rápidas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickActions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final action = _quickActions[index];
                  return _QuickActionCard(
                    icon: action.icon,
                    label: action.label,
                    onTap: () {
                      Navigator.pop(context); // Cerrar modal
                      _handleQuickAction(action);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(orgAdminHomeSummaryProvider);
    final profileAsync = ref.watch(profileProvider);

    final userName = profileAsync.maybeWhen(
      data: (p) =>
          (p?.nombres.trim().isNotEmpty ?? false) ? p!.nombres : 'Admin',
      orElse: () => 'Admin',
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: summaryAsync.when(
        data: (summary) {
          return Column(
            children: [
              HomeHeader(
                userName: userName,
                organizationName: summary.organization.razonSocial,
                roleName: 'Administrador',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    try {
                      ref
                        ..invalidate(orgAdminHomeSummaryProvider)
                        ..invalidate(orgAdminAlertsProvider)
                        ..invalidate(orgAdminPaymentsProvider);
                      await ref.read(orgAdminHomeSummaryProvider.future);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo refrescar: $e'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                    children: [
                      _SubscriptionBanner(org: summary.organization),
                      const SizedBox(height: 10),

                      // Layout personalizado de KPIs
                      // Principal: Asistencias y Alertas
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: AdminStatCard(
                              label: 'Asistencias hoy',
                              value: '${summary.attendanceToday}',
                              hint:
                                  '${summary.geofenceIssuesToday} incidencias de geocerca',
                              icon: Icons.access_time_filled,
                              color: AppColors.infoBlue,
                              onTap: () => _goToTab(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: AdminStatCard(
                              label: 'Alertas',
                              value: '${summary.pendingAlerts}',
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.errorRed,
                              hint: 'Requiere atención',
                              onTap: () =>
                                  context.push(AppRoutes.orgAdminAlerts),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Secundarios: Colaboradores y Permisos
                      Row(
                        children: [
                          Expanded(
                            child: AdminStatCard(
                              label: 'Equipo',
                              value:
                                  '${summary.staffActive}/${summary.staffTotal}',
                              hint: 'Activos',
                              icon: Icons.groups,
                              onTap: () => _goToTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdminStatCard(
                              label: 'Permisos',
                              value: '${summary.pendingPermissions}',
                              hint: 'Pendientes',
                              icon: Icons.assignment,
                              color: AppColors.warningOrange,
                              onTap: () => _goToTab(3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tarjeta de Configuración
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRed,
                              AppColors.primaryRed.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Configuración Global',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Gestiona las reglas de asistencia, horas extras y tolerancias de tu organización.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryRed,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () =>
                                    context.push(AppRoutes.orgAdminLegalConfig),
                                child: const Text('Ajustar Parámetros'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorText('$e'),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        onPressed: _showQuickActionsSheet,
        child: const Icon(Icons.grid_view_rounded),
      ),
    );
  }

  void _handleQuickAction(_QuickActionData action) {
    if (!mounted) return;

    final tabIndex = action.tabIndex;
    final route = action.route;

    if (tabIndex != null) {
      _goToTab(tabIndex);
      return;
    }

    if (route != null) {
      context.push(route);
    }
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String? route;
  final int? tabIndex;

  const _QuickActionData._({
    required this.icon,
    required this.label,
    this.route,
    this.tabIndex,
  });

  const _QuickActionData.route({
    required IconData icon,
    required String label,
    required String route,
  }) : this._(icon: icon, label: label, route: route);

  const _QuickActionData.tab({
    required IconData icon,
    required String label,
    required int tabIndex,
  }) : this._(icon: icon, label: label, tabIndex: tabIndex);
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 28),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  final Organizaciones org;

  const _SubscriptionBanner({required this.org});

  @override
  Widget build(BuildContext context) {
    final state = org.getSubscriptionState();
    if (state == null || !state.shouldShowBanner) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final style = _SubscriptionBannerStyle.fromState(state);
    final message = _subscriptionMessage(state, now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${style.title}: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: style.textColor,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: style.textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.status != SubscriptionStatus.active)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: style.textColor.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }

  String _subscriptionMessage(SubscriptionState state, DateTime now) {
    final base = date_utils.humanRemainingText(now, state.endDate);
    switch (state.status) {
      case SubscriptionStatus.expired:
        return '$base. Renueva ahora.';
      case SubscriptionStatus.expiresToday:
        return 'Vence hoy.';
      case SubscriptionStatus.expiringIn7Days:
        return '$base.';
      case SubscriptionStatus.expiringIn15Days:
        return '$base.';
      case SubscriptionStatus.active:
        return '';
    }
  }
}

class _SubscriptionBannerStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String title;

  const _SubscriptionBannerStyle({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.title,
  });

  factory _SubscriptionBannerStyle.fromState(SubscriptionState state) {
    switch (state.status) {
      case SubscriptionStatus.expired:
        return _SubscriptionBannerStyle(
          icon: Icons.error_outline,
          iconColor: Colors.red.shade700,
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade300,
          textColor: Colors.red.shade900,
          title: 'Vencida',
        );
      case SubscriptionStatus.expiresToday:
        return const _SubscriptionBannerStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warningOrange,
          backgroundColor: Color(0xFFFFF4E6),
          borderColor: Color(0xFFFFD699),
          textColor: Color(0xFF996600),
          title: 'Vence hoy',
        );
      case SubscriptionStatus.expiringIn7Days:
        return const _SubscriptionBannerStyle(
          icon: Icons.timer,
          iconColor: AppColors.warningOrange,
          backgroundColor: Color(0xFFFFF4E6),
          borderColor: Color(0xFFFFD699),
          textColor: Color(0xFF996600),
          title: 'Por vencer',
        );
      case SubscriptionStatus.expiringIn15Days:
        return const _SubscriptionBannerStyle(
          icon: Icons.info_outline,
          iconColor: AppColors.infoBlue,
          backgroundColor: Color(0xFFE3F2FD),
          borderColor: Color(0xFF90CAF9),
          textColor: Color(0xFF0D47A1),
          title: 'Próximo vencimiento',
        );
      case SubscriptionStatus.active:
        return const _SubscriptionBannerStyle(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.successGreen,
          backgroundColor: Colors.transparent,
          borderColor: AppColors.successGreen,
          textColor: AppColors.successGreen,
          title: 'Activa',
        );
    }
  }
}
