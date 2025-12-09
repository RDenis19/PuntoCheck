import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/manager/views/manager_approvals_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_hours_bank_view.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Dashboard del Manager con estadísticas en tiempo real del equipo.
/// Incluye botón flotante con menú de acciones rápidas.
class ManagerDashboardView extends ConsumerStatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  ConsumerState<ManagerDashboardView> createState() =>
      _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends ConsumerState<ManagerDashboardView> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(managerHomeSummaryProvider);

    return SafeArea(
      child: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error cargando dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          return Stack(
            children: [
              // Contenido principal
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(managerHomeSummaryProvider);
                },
                color: AppColors.primaryRed,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Fila 1: Presentes y Tardanzas
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Presentes hoy',
                            value: '${summary.teamPresent}',
                            hint: 'De ${summary.teamTotal} en equipo',
                            icon: Icons.check_circle_outline,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Tardanzas',
                            value: '${summary.teamLate}',
                            hint: 'Supera tolerancia',
                            icon: Icons.schedule_outlined,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila 2: Permisos pendientes y Horas extra
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Permisos pendientes',
                            value: '${summary.pendingPermissions}',
                            hint: 'Requieren aprobación',
                            icon: Icons.mail_outline,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Horas extra',
                            value: '${summary.overtimeHoursWeek}',
                            hint: 'Acumulado semanal',
                            icon: Icons.trending_up,
                            color: AppColors.infoBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // Espacio para FAB
                  ],
                ),
              ),

              // Botón flotante con menú
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_showActions) ...[
                      _QuickAction(
                        icon: Icons.approval_outlined,
                        label: 'Aprobar permisos',
                        onTap: () {
                          setState(() => _showActions = false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerApprovalsView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _QuickAction(
                        icon: Icons.access_time_rounded,
                        label: 'Banco de horas',
                        onTap: () {
                          setState(() => _showActions = false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerHoursBankView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    FloatingActionButton(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      onPressed: () =>
                          setState(() => _showActions = !_showActions),
                      child: Icon(_showActions ? Icons.close : Icons.add),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Widget de acción rápida (reutilizado del patrón del Admin)
// ============================================================================

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

/// Sección de acciones rápidas para el manager.
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionTile(
          icon: Icons.people_outline,
          title: 'Ver mi equipo',
          subtitle: 'Lista completa de empleados',
          color: AppColors.primaryRed,
          onTap: () {
            // El cambio de tab lo maneja el shell
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ve a la pestaña "Mi Equipo"'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const Divider(height: 1),
        _QuickActionTile(
          icon: Icons.approval_outlined,
          title: 'Permisos pendientes',
          subtitle: 'Revisar solicitudes',
          color: AppColors.warningOrange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ve a la pestaña "Aprobaciones"'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Tile para acción rápida.
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
