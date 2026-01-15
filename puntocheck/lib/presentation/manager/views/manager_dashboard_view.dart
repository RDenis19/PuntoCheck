import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:puntocheck/presentation/manager/views/manager_approvals_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_branch_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_compliance_alerts_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_hours_bank_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_leave_detail_view.dart'; // Import Detail View
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

    // SafeArea rernoved to prevent double padding/gap, handled by Shell
    return summaryAsync.when(
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
                  Icons.error_outline_rounded,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // Título Resumen
                    const Text(
                      'RESUMEN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fila 1: Presentes y Tardanzas (Tarjetas Rojas)
                    Row(
                      children: [
                        Expanded(
                          child: _RedStatCard(
                            label: 'Presentes hoy',
                            value: '${summary.teamPresent}',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RedStatCard(
                            label: 'Tardanzas',
                            value: '${summary.teamLate}',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila 2: Permisos pendientes y Horas extra (Tarjetas Rojas)
                    Row(
                      children: [
                        Expanded(
                          child: _RedStatCard(
                            label: 'Pendientes',
                            value: '${summary.pendingPermissions}',
                            icon: Icons.mail_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RedStatCard(
                            label: 'Horas extra',
                            value: '${summary.overtimeHoursWeek}',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Título Solicitudes Recientes
                    if (summary.recentPermissions.isNotEmpty) ...[
                      const Text(
                        'SOLICITUDES RECIENTES',
                         style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...summary.recentPermissions.map((permission) {
                        return _RecentRequestCard(
                          request: permission,
                          onTap: () async {
                             // Navegar al detalle para aprobar/rechazar
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManagerLeaveDetailView(
                                    request: permission,
                                  ),
                                ),
                              );
                              // Si cambió algo (aprobó/rechazó), provider auto-refresh lo captará eventualemente
                              // pero forzamos refresh inmediato por UX
                              if (changed == true) {
                                ref.invalidate(managerHomeSummaryProvider);
                                ref.invalidate(managerTeamPermissionsProvider);
                              }
                          },
                        );
                      }),
                      const SizedBox(height: 80),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No hay solicitudes recientes',
                            style: TextStyle(color: AppColors.neutral500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
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
                        icon: Icons.approval_rounded,
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
                        icon: Icons.store_mall_directory_rounded,
                        label: 'Mi sucursal',
                        onTap: () {
                          setState(() => _showActions = false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerBranchView(),
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
                      _QuickAction(
                        icon: Icons.shield_rounded,
                        label: 'Alertas',
                        onTap: () {
                          setState(() => _showActions = false);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManagerComplianceAlertsView(),
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
                      child: Icon(_showActions ? Icons.close_rounded : Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }
}

// ============================================================================
// WIDGET LOCALS
// ============================================================================

/// Tarjeta de estadística roja con ícono blanco y texto blanco, 
/// estilo "block" uniforme.
class _RedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RedStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura fija para uniformidad ("del mismo porte")
      height: 100, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icono y Valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta compacta para solicitudes recientes (solo Nombre, Fecha, Tipo)
class _RecentRequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const _RecentRequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Helper para fecha "17 Dic"
    String formatDate(DateTime d) {
      const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${d.day} ${months[d.month-1]}';
    }

    final nombre = request.solicitanteNombreCompleto;
    final fecha = formatDate(request.creadoEn ?? DateTime.now());
    final tipo = request.tipo.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)), // Borde rojo suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar simple
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.neutral400),
              ),
              const SizedBox(width: 12),
              
              // Info: Nombre y Fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 4),
                     Text(
                       fecha,
                       style: const TextStyle(
                         fontSize: 13,
                         color: AppColors.neutral500,
                       ),
                     ),
                  ],
                ),
              ),

              // Chip de Tipo (destacado suave)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tipo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
        ),
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
