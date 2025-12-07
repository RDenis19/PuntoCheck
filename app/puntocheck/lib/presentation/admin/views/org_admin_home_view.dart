import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_alerts_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branches_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_edit_org_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_payments_view.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminHomeView extends ConsumerStatefulWidget {
  const OrgAdminHomeView({super.key});

  @override
  ConsumerState<OrgAdminHomeView> createState() => _OrgAdminHomeViewState();
}

class _OrgAdminHomeViewState extends ConsumerState<OrgAdminHomeView> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(orgAdminHomeSummaryProvider);
    final alertsAsync = ref.watch(orgAdminAlertsProvider);
    final paymentsAsync = ref.watch(orgAdminPaymentsProvider);

    return summaryAsync.when(
      data: (summary) => RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(orgAdminHomeSummaryProvider)
            ..invalidate(orgAdminAlertsProvider)
            ..invalidate(orgAdminPaymentsProvider);
          await ref.read(orgAdminHomeSummaryProvider.future);
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
                    ),
                    AdminStatCard(
                      label: 'Asistencias hoy',
                      value: '${summary.attendanceToday}',
                      hint: '${summary.geofenceIssuesToday} fuera de geocerca',
                      icon: Icons.access_time_filled,
                      color: AppColors.infoBlue,
                    ),
                    AdminStatCard(
                      label: 'Permisos pendientes',
                      value: '${summary.pendingPermissions}',
                      icon: Icons.assignment,
                      color: AppColors.warningOrange,
                    ),
                    AdminStatCard(
                      label: 'Alertas legales',
                      value: '${summary.pendingAlerts}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.errorRed,
                      hint: 'Revisa cumplimiento',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Pagos de suscripci\u00f3n',
                  child: paymentsAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return const _EmptyWithIcon(
                          icon: Icons.receipt_long_outlined,
                          text: 'Sin pagos pendientes',
                        );
                      }
                      return Column(
                        children: list.take(3).map((pago) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Pago ${pago.id}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Monto: ${pago.monto.toStringAsFixed(2)} | Estado: ${pago.estado?.value ?? 'pendiente'}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _ErrorText('$e'),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Alertas de cumplimiento',
                  child: alertsAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return const _EmptyWithIcon(
                          icon: Icons.shield_outlined,
                          text: 'Sin alertas pendientes',
                        );
                      }
                      return Column(
                        children: list.take(3).map((alert) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.shield_moon_outlined),
                            title: Text(
                              alert.tipoIncumplimiento,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(alert.detalleTecnico?['descripcion'] ??
                                'Detalle no disponible'),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _ErrorText('$e'),
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
                    _QuickAction(
                      icon: Icons.edit,
                      label: 'Editar organización',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminEditOrgView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.store_mall_directory_outlined,
                      label: 'Sucursales',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminBranchesView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.receipt_long,
                      label: 'Pagos y suscripción',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminPaymentsView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.shield,
                      label: 'Alertas',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminAlertsView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  FloatingActionButton(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    onPressed: () => setState(() => _showActions = !_showActions),
                    child: Icon(_showActions ? Icons.close : Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorText('$e'),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyWithIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyWithIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.neutral700),
            ),
          ),
        ],
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
              'Error: $text',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 20),
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
    );
  }
}
