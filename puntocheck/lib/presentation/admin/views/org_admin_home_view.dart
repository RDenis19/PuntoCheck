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

class OrgAdminHomeView extends ConsumerStatefulWidget {
  const OrgAdminHomeView({super.key});

  @override
  ConsumerState<OrgAdminHomeView> createState() => _OrgAdminHomeViewState();
}

class _OrgAdminHomeViewState extends ConsumerState<OrgAdminHomeView> {
  bool _showActions = false;

  List<_QuickActionData> get _quickActions => const [
    _QuickActionData.route(
      icon: Icons.edit_rounded,
      label: 'Editar organizacion',
      route: AppRoutes.orgAdminEditOrg,
    ),
    _QuickActionData.route(
      icon: Icons.store_mall_directory_outlined,
      label: 'Sucursales',
      route: AppRoutes.orgAdminBranches,
    ),
    _QuickActionData.route(
      icon: Icons.receipt_long_rounded,
      label: 'Pagos y suscripcion',
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

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(orgAdminHomeSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        return RefreshIndicator(
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
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 4),
                  Text(
                    summary.organization.razonSocial,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SubscriptionBanner(org: summary.organization),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      AdminStatCard(
                        label: 'Colaboradores',
                        value: '${summary.staffActive}/${summary.staffTotal}',
                        hint: 'Activos / total',
                        icon: Icons.groups,
                        onTap: () => _goToTab(1),
                      ),
                      AdminStatCard(
                        label: 'Asistencias hoy',
                        value: '${summary.attendanceToday}',
                        hint:
                            '${summary.geofenceIssuesToday} fuera de geocerca',
                        icon: Icons.access_time_filled,
                        color: AppColors.infoBlue,
                        onTap: () => _goToTab(2),
                      ),
                      AdminStatCard(
                        label: 'Permisos pendientes',
                        value: '${summary.pendingPermissions}',
                        icon: Icons.assignment,
                        color: AppColors.warningOrange,
                        onTap: () => _goToTab(3),
                      ),
                      AdminStatCard(
                        label: 'Alertas legales',
                        value: '${summary.pendingAlerts}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.errorRed,
                        hint: 'Revisa cumplimiento',
                        onTap: () => context.push(AppRoutes.orgAdminAlerts),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.rule, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Configuracion legal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ajusta tolerancia, descanso, horas extra e inicio nocturno.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: const Text('Ajustar configuracion'),
                            onPressed: () =>
                                context.push(AppRoutes.orgAdminLegalConfig),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_showActions) ...[
                      for (var i = 0; i < _quickActions.length; i++) ...[
                        _QuickAction(
                          icon: _quickActions[i].icon,
                          label: _quickActions[i].label,
                          onTap: () => _handleQuickAction(_quickActions[i]),
                        ),
                        if (i < _quickActions.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                    FloatingActionButton(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      onPressed: () =>
                          setState(() => _showActions = !_showActions),
                      child: Icon(_showActions ? Icons.close_rounded : Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorText('$e'),
    );
  }

  void _handleQuickAction(_QuickActionData action) {
    setState(() => _showActions = false);
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: style.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: style.textColor.withValues(alpha: 0.8),
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

  String _subscriptionMessage(SubscriptionState state, DateTime now) {
    final base = date_utils.humanRemainingText(now, state.endDate);
    switch (state.status) {
      case SubscriptionStatus.expired:
        return '$base. Contacta a soporte para reactivar.';
      case SubscriptionStatus.expiresToday:
        return '$base. Renueva hoy para evitar interrupciones.';
      case SubscriptionStatus.expiringIn7Days:
        return '$base. Renueva pronto.';
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
          title: 'Suscripcion vencida',
        );
      case SubscriptionStatus.expiresToday:
        return _SubscriptionBannerStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warningOrange,
          backgroundColor: const Color(0xFFFFF4E6),
          borderColor: const Color(0xFFFFD699),
          textColor: const Color(0xFF996600),
          title: 'Suscripcion vence hoy',
        );
      case SubscriptionStatus.expiringIn7Days:
        return _SubscriptionBannerStyle(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warningOrange,
          backgroundColor: const Color(0xFFFFF4E6),
          borderColor: const Color(0xFFFFD699),
          textColor: const Color(0xFF996600),
          title: 'Suscripcion por vencer',
        );
      case SubscriptionStatus.expiringIn15Days:
        return _SubscriptionBannerStyle(
          icon: Icons.info_outline,
          iconColor: AppColors.infoBlue,
          backgroundColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          textColor: const Color(0xFF0D47A1),
          title: 'Renovacion proxima',
        );
      case SubscriptionStatus.active:
        return _SubscriptionBannerStyle(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.successGreen,
          backgroundColor: Colors.transparent,
          borderColor: AppColors.successGreen,
          textColor: AppColors.successGreen,
          title: 'Suscripcion activa',
        );
    }
  }
}
