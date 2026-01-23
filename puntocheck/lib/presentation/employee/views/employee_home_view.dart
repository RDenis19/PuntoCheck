import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:puntocheck/models/employee_schedule.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/employee/views/employee_notifications_view.dart';
import 'package:puntocheck/presentation/shared/widgets/home_header.dart';
import 'package:puntocheck/presentation/employee/views/employee_mark_attendance_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_hours_bank_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_schedule_view.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/services/attendance_summary_helper.dart';
import 'package:puntocheck/services/schedule_display_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeHomeView extends ConsumerStatefulWidget {
  const EmployeeHomeView({super.key});

  @override
  ConsumerState<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends ConsumerState<EmployeeHomeView> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(employeeScheduleProvider);
    final EmployeeSchedule? schedule = scheduleAsync.valueOrNull;
    final RegistrosAsistencia? lastAttendance = ref
        .watch(lastAttendanceProvider)
        .valueOrNull;
    final historyAsync = ref.watch(employeeAttendanceHistoryProvider);
    final history = historyAsync.valueOrNull ?? const <RegistrosAsistencia>[];

    // Header Data
    final profileAsync = ref.watch(employeeProfileProvider);
    final branchesAsync = ref.watch(employeeBranchesProvider);
    final notificationsAsync = ref.watch(employeeNotificationsProvider);

    final profile = profileAsync.valueOrNull;

    // Logic for Branch Name
    String? displayOrgName;
    if (profile != null) {
      final branches = branchesAsync.valueOrNull ?? const [];
      final assignedId = (profile.sucursalId ?? '').trim();
      final assigned = assignedId.isEmpty
          ? null
          : branches.where((b) => b.id == assignedId).toList();

      final branchName = assigned?.isNotEmpty == true
          ? assigned!.first.nombre
          : (branches.length == 1 ? branches.first.nombre : null);

      if (branchName != null) {
        displayOrgName = 'Sucursal: $branchName';
      } else if (profile.sucursalId != null && profile.sucursalId!.isNotEmpty) {
        displayOrgName =
            'Sucursal asignada: ${profile.sucursalId!.substring(0, 8)}...';
      } else {
        displayOrgName = 'Sucursal: Sin asignar';
      }
    }

    // Fecha actual formateada
    final now = DateTime.now();
    final dateString = DateFormat("EEEE, d 'de' MMMM", 'es').format(now);
    final formattedDate = dateString[0].toUpperCase() + dateString.substring(1);

    final todaySummary = _computeTodaySummary(history, now);
    final workedText = todaySummary != null
        ? _fmtDuration(todaySummary.workedNet)
        : '0h 0m';
    final status = _computeStatus(lastAttendance, now);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        heroTag: 'employee_home_actions_fab',
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        onPressed: () => _openQuickActions(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Header Reutilizable
          HomeHeader(
            userName: profile?.nombres ?? 'Empleado',
            roleName: profile?.cargo ?? 'Operario',
            organizationName: displayOrgName,
            notificationCount:
                notificationsAsync.valueOrNull
                    ?.where((n) => n['leido'] != true)
                    .length ??
                0,
            onNotificationTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmployeeNotificationsView(),
                ),
              );
            },
          ),

          // Contenido desplazable
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () async {
                ref
                  ..invalidate(employeeScheduleProvider)
                  ..invalidate(lastAttendanceProvider)
                  ..invalidate(employeeAttendanceHistoryProvider)
                  ..invalidate(employeeNotificationsProvider);
                final schedule = await ref.refresh(
                  employeeScheduleProvider.future,
                );
                if (schedule == null) {
                  ref.invalidate(employeeNextScheduleProvider);
                }
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMainActionCard(context, ref, lastAttendance),
                  const SizedBox(height: 24),
                  const Text(
                    'Tu turno de hoy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShiftCard(schedule),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.access_time_filled_rounded,
                          color: AppColors.infoBlue,
                          value: historyAsync.isLoading ? '—' : workedText,
                          label: 'Trabajadas hoy',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryItem(
                          icon: status.icon,
                          color: status.color,
                          value: status.label,
                          label: 'Estado',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta Grande de Acción Principal
  Widget _buildMainActionCard(
    BuildContext context,
    WidgetRef ref,
    RegistrosAsistencia? lastRecord,
  ) {
    final bool isEntry =
        lastRecord == null || lastRecord.tipoRegistro == 'salida';
    final String actionLabel = isEntry ? 'Marcar Entrada' : 'Marcar Salida';
    final IconData actionIcon = isEntry
        ? Icons.login_rounded
        : Icons.logout_rounded;
    final Color actionColor = isEntry
        ? AppColors.successGreen
        : AppColors.primaryRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono circular grande animado (simulado)
          GestureDetector(
            onTap: () {
              // Navegar a la vista de marcación
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeMarkAttendanceView(
                    actionType: isEntry ? 'entrada' : 'salida',
                  ),
                ),
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: actionColor.withValues(alpha: 0.2),
                  width: 8,
                ),
              ),
              child: Icon(actionIcon, size: 48, color: actionColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEntry ? 'Comienza tu jornada' : 'Finaliza tu jornada',
            style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de Turno
  Widget _buildShiftCard(EmployeeSchedule? schedule) {
    if (schedule == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_busy_rounded, color: AppColors.neutral500),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes turno asignado para hoy',
                style: TextStyle(color: AppColors.neutral600),
              ),
            ),
          ],
        ),
      );
    }

    final plantilla = schedule.plantilla;
    final turnos = ScheduleDisplayHelper.sortedTurns(plantilla);
    final horarioStr = turnos.isNotEmpty
        ? ScheduleDisplayHelper.formatTurnsSegments(turnos)
        : ScheduleDisplayHelper.formatTemplateSummary(plantilla);
    final tolerance = plantilla.toleranciaEntradaMinutos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.infoBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horarioStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plantilla.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutral600,
                  ),
                ),
                if (tolerance != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tolerancia de entrada: $tolerance min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  AttendanceDaySummary? _computeTodaySummary(
    List<RegistrosAsistencia> history,
    DateTime now,
  ) {
    if (history.isEmpty) return null;
    final today = DateTime(now.year, now.month, now.day);
    final todayRecords = history
        .where(
          (r) =>
              r.fechaHoraMarcacion.year == today.year &&
              r.fechaHoraMarcacion.month == today.month &&
              r.fechaHoraMarcacion.day == today.day,
        )
        .toList();
    if (todayRecords.isEmpty) return null;
    return AttendanceSummaryHelper.groupByDay(todayRecords).firstOrNull;
  }

  _HomeStatus _computeStatus(RegistrosAsistencia? last, DateTime now) {
    if (last == null) {
      return const _HomeStatus(
        label: 'Sin entrada',
        icon: Icons.info_outline_rounded,
        color: AppColors.neutral600,
      );
    }

    final isToday =
        last.fechaHoraMarcacion.year == now.year &&
        last.fechaHoraMarcacion.month == now.month &&
        last.fechaHoraMarcacion.day == now.day;
    if (!isToday) {
      return const _HomeStatus(
        label: 'Sin entrada hoy',
        icon: Icons.info_outline,
        color: AppColors.neutral600,
      );
    }

    switch (last.tipoRegistro) {
      case 'entrada':
        return const _HomeStatus(
          label: 'En jornada',
          icon: Icons.play_circle_fill_rounded,
          color: AppColors.infoBlue,
        );
      case 'inicio_break':
        return const _HomeStatus(
          label: 'En break',
          icon: Icons.free_breakfast_rounded,
          color: AppColors.warningOrange,
        );
      case 'fin_break':
        return const _HomeStatus(
          label: 'En jornada',
          icon: Icons.play_circle_fill_rounded,
          color: AppColors.infoBlue,
        );
      case 'salida':
        return const _HomeStatus(
          label: 'Cerrado',
          icon: Icons.check_circle_rounded,
          color: AppColors.successGreen,
        );
      default:
        return const _HomeStatus(
          label: 'Estado',
          icon: Icons.info_outline_rounded,
          color: AppColors.neutral600,
        );
    }
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  void _openQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.schedule_rounded,
                    title: 'Mi horario',
                    subtitle: 'Ver turnos, tolerancia y vigencia',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmployeeScheduleView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Banco de horas',
                    subtitle: 'Horas acumuladas y días compensatorios',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmployeeHoursBankView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeStatus {
  final String label;
  final IconData icon;
  final Color color;
  const _HomeStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
