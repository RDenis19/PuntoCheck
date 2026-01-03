import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_notifications_action.dart';
import 'package:puntocheck/presentation/employee/widgets/attendance/employee_attendance_day_card.dart';
import 'package:puntocheck/presentation/employee/widgets/attendance/employee_attendance_detail_sheet.dart';
import 'package:puntocheck/presentation/employee/widgets/attendance/employee_attendance_filters.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/services/attendance_summary_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeAttendanceView extends ConsumerStatefulWidget {
  const EmployeeAttendanceView({super.key});

  @override
  ConsumerState<EmployeeAttendanceView> createState() =>
      _EmployeeAttendanceViewState();
}

class _EmployeeAttendanceViewState extends ConsumerState<EmployeeAttendanceView> {
  final _dateFmt = DateFormat('EEE, dd MMM', 'es');
  final _timeFmt = DateFormat('HH:mm');

  AttendanceFilters _filters = const AttendanceFilters();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(employeeAttendanceHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          const EmployeeNotificationsAction(),
          IconButton(
            tooltip: 'Filtrar',
            onPressed: () async {
              final next = await showModalBottomSheet<AttendanceFilters>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EmployeeAttendanceFiltersSheet(initial: _filters),
              );
              if (!mounted || next == null) return;
              setState(() => _filters = next);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeeAttendanceHistoryProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => EmployeeAttendanceErrorView(
            message: 'No se pudo cargar tu historial.\n$e',
            onRetry: () => ref.invalidate(employeeAttendanceHistoryProvider),
          ),
          data: (history) {
            if (history.isEmpty) {
              return const EmptyState(
                icon: Icons.history_rounded,
                title: 'Sin registros',
                message: 'Tu historial de asistencia aparecerá aquí.',
              );
            }

            final filtered = _filters.apply(history);
            if (filtered.isEmpty) {
              return EmployeeAttendanceNoResultsView(
                onClear: () => setState(() => _filters = const AttendanceFilters()),
              );
            }

            final days = AttendanceSummaryHelper.groupByDay(filtered);
            final now = DateTime.now();
            final monthDays = days
                .where((d) => d.day.year == now.year && d.day.month == now.month)
                .toList();
            final month = AttendanceSummaryHelper.summarizeMonth(monthDays);

            final todayDay = AttendanceSummaryHelper.dateOnly(now);
            final today = days.where((d) => d.day == todayDay).firstOrNull;

            return RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () async => ref.refresh(employeeAttendanceHistoryProvider.future),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EmployeeAttendanceSummaryHeader(today: today, month: month),
                          const SizedBox(height: 12),
                          EmployeeAttendanceActiveFiltersBar(
                            filters: _filters,
                            onEdit: () async {
                              final next =
                                  await showModalBottomSheet<AttendanceFilters>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    EmployeeAttendanceFiltersSheet(initial: _filters),
                              );
                              if (!mounted || next == null) return;
                              setState(() => _filters = next);
                            },
                            onClear: () =>
                                setState(() => _filters = const AttendanceFilters()),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Historial',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          index == days.length - 1 ? 16 : 0,
                        ),
                        child: EmployeeAttendanceDayCard(
                          day: day,
                          dateFmt: _dateFmt,
                          timeFmt: _timeFmt,
                          onTapRecord: (r) => _openRecordDetail(context, r),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRecordDetail(BuildContext context, RegistrosAsistencia record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeeAttendanceDetailSheet(record: record, timeFmt: _timeFmt),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
