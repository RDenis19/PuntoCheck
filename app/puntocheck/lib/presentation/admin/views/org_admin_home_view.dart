import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_alerts_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branches_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_edit_org_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_hours_bank_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_leaves_hours_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_legal_config_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_payments_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_schedule_assignments_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_schedules_view.dart';
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
                // Banner de suscripción
                _SubscriptionBanner(org: summary.organization),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OrgAdminLegalConfigView(),
                              ),
                            );
                          },
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
                    _QuickAction(
                      icon: Icons.edit,
                      label: 'Editar organizacion',
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
                      label: 'Pagos y suscripcion',
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
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.schedule_outlined,
                      label: 'Plantillas Horarios',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminSchedulesView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.assignment_ind_rounded,
                      label: 'Asignaciones',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminScheduleAssignmentsView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.access_time_filled,
                      label: 'Banco de Horas',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminHoursBankView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _QuickAction(
                      icon: Icons.event_note_outlined,
                      label: 'Permisos',
                      onTap: () {
                        setState(() => _showActions = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrgAdminLeavesAndHoursView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
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

// ============================================================================
// Banner de estado de suscripción
// ============================================================================
class _SubscriptionBanner extends StatelessWidget {
  final Organizaciones org;

  const _SubscriptionBanner({required this.org});

  @override
  Widget build(BuildContext context) {
    final estado = _getSubscriptionState();
    if (estado == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estado.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: estado.borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(estado.icon, color: estado.iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estado.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: estado.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  estado.message,
                  style: TextStyle(
                    color: estado.textColor.withValues(alpha: 0.8),
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

  _SubscriptionState? _getSubscriptionState() {
    final now = DateTime.now();
    final fechaFin = org.fechaFinSuscripcion;
    final estado = org.estadoSuscripcion;

    // Si no hay fecha fin, no mostrar banner
    if (fechaFin == null) return null;

    final diasRestantes = fechaFin.difference(now).inDays;

    // Suscripción vencida
    if (diasRestantes < 0 || estado?.value == 'vencida') {
      return _SubscriptionState(
        icon: Icons.error_outline,
        iconColor: Colors.red.shade700,
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade300,
        textColor: Colors.red.shade900,
        title: '⚠️ Suscripción vencida',
        message:
            'Tu suscripción venció hace ${diasRestantes.abs()} días. Contacta a soporte.',
      );
    }

    // Próxima a vencer (menos de 7 días)
    if (diasRestantes <= 7) {
      return _SubscriptionState(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warningOrange,
        backgroundColor: const Color(0xFFFFF4E6),
        borderColor: const Color(0xFFFFD699),
        textColor: const Color(0xFF996600),
        title: 'Suscripción por vencer',
        message:
            'Tu suscripción vence en $diasRestantes día${diasRestantes == 1 ? '' : 's'}. Renueva pronto.',
      );
    }

    // Próxima a vencer (menos de 15 días)
    if (diasRestantes <= 15) {
      return _SubscriptionState(
        icon: Icons.info_outline,
        iconColor: AppColors.infoBlue,
        backgroundColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFF90CAF9),
        textColor: const Color(0xFF0D47A1),
        title: 'Renovación próxima',
        message: 'Tu suscripción vence en $diasRestantes días.',
      );
    }

    // Activa y con tiempo suficiente - no mostrar banner
    return null;
  }
}

// Clase helper para estado de suscripción
class _SubscriptionState {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String title;
  final String message;

  const _SubscriptionState({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.title,
    required this.message,
  });
}
