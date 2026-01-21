import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:puntocheck/presentation/manager/views/manager_approvals_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_branch_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_compliance_alerts_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_hours_bank_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_leave_detail_view.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/manager/views/manager_notifications_view.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Dashboard del Manager "Command Center".
/// Estilo moderno, KPIs visuales y acciones en BottomSheet.
class ManagerDashboardView extends ConsumerStatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  ConsumerState<ManagerDashboardView> createState() =>
      _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends ConsumerState<ManagerDashboardView> {
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ActionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(managerHomeSummaryProvider);
    final profileAsync = ref.watch(managerProfileProvider);
    final notificationsAsync = ref.watch(
      managerUnreadNotificationsCountProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.secondaryWhite,
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summary) {
          return CustomScrollView(
            slivers: [
              // 1. Sliver App Bar con Saludo y Fecha
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: const Text(
                  'Dashboard',
                  style: TextStyle(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManagerNotificationsView(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.neutral900,
                        ),
                      ),
                      if ((notificationsAsync.valueOrNull ?? 0) > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.neutral600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profileAsync.valueOrNull?.nombres ?? 'Manager',
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEEE d, MMMM',
                                'es',
                              ).format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral500.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. KPIs Section (Command Cards)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    // Fila Principal: Presentes y Tardanzas (Con gradiente suave)
                    Row(
                      children: [
                        Expanded(
                          child: _GradientKpiCard(
                            label: 'Presentes',
                            value: '${summary.teamPresent}',
                            icon: Icons.check_circle_outline_rounded,
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryRed, Color(0xFFE53935)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GradientKpiCard(
                            label: 'Tardanzas',
                            value: '${summary.teamLate}',
                            icon: Icons.schedule_rounded,
                            // Un tono naranja/ámbar para alerta sin ser error crítico
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB8C00), Color(0xFFF57C00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Fila Secundaria: Pendientes y Horas Extra (Estilo más limpio)
                    Row(
                      children: [
                        Expanded(
                          child: _CleanKpiCard(
                            label: 'Solicitudes',
                            value: '${summary.pendingPermissions}',
                            icon: Icons.mark_email_unread_outlined,
                            accentColor: AppColors.infoBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CleanKpiCard(
                            label: 'Horas Extra',
                            value: '${summary.overtimeHoursWeek}',
                            icon: Icons.trending_up_rounded,
                            accentColor: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 3. Solicitudes Recientes (Inbox Style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Actividad Reciente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManagerApprovalsView(),
                              ),
                            );
                          },
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),

              // Lista de Solicitudes
              if (summary.recentPermissions.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Todo al día. No hay solicitudes nuevas.',
                        style: TextStyle(color: AppColors.neutral500),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = summary.recentPermissions[index];
                    return _RecentRequestTile(request: item);
                  }, childCount: summary.recentPermissions.length),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActions(context),
        backgroundColor: AppColors.primaryRed,
        elevation: 4,
        child: const Icon(Icons.grid_view_rounded, color: Colors.white),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }
}

// -----------------------------------------------------------------------------
// WIDGETS
// -----------------------------------------------------------------------------

class _GradientKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _GradientKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _CleanKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                  height: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRequestTile extends StatelessWidget {
  final SolicitudesPermisos request;
  const _RecentRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    // Usamos InkWell para efecto ripple
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          // Navegar al detalle
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ManagerLeaveDetailView(request: request),
            ),
          );
          // El refresh se maneja por riverpod provider invalidate si es necesario
          // pero idealmente deberíamos invalidar al volver si cambió.
          // Por simplicidad, confiamos en auto-disposables o refresh manual
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.neutral100,
          child: Text(
            (request.solicitanteNombreCompleto ?? '?').substring(0, 1),
            style: const TextStyle(
              color: AppColors.neutral700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          request.solicitanteNombreCompleto ?? 'Desconocido',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${request.tipo.label} • ${_formatDate(request.creadoEn)}',
          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.neutral400,
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd MMM').format(d);
  }
}

class _ActionsBottomSheet extends StatelessWidget {
  const _ActionsBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.approval_rounded,
                label: 'Aprobar',
                color: AppColors.primaryRed,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerApprovalsView(),
                  ),
                ),
              ),
              _ActionButton(
                icon: Icons.store_mall_directory_rounded,
                label: 'Sucursal',
                color: AppColors.infoBlue,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerBranchView()),
                ),
              ),
              _ActionButton(
                icon: Icons.access_time_rounded,
                label: 'Banco Hs',
                color: Colors.orange,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerHoursBankView(),
                  ),
                ),
              ),
              _ActionButton(
                icon: Icons.shield_rounded,
                label: 'Alertas',
                color: Colors.purple,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerComplianceAlertsView(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
