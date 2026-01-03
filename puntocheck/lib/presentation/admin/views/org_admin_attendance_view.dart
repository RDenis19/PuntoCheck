import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_filter_sheet.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_record_detail_sheet.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_record_card.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_stats_section.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/models/attendance_filters.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminAttendanceView extends ConsumerStatefulWidget {
  const OrgAdminAttendanceView({super.key});

  @override
  ConsumerState<OrgAdminAttendanceView> createState() =>
      _OrgAdminAttendanceViewState();
}

class _OrgAdminAttendanceViewState
    extends ConsumerState<OrgAdminAttendanceView> {
  DateTime _selectedDate = DateTime.now();
  AttendanceFilters _filters = const AttendanceFilters();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(hours: 23, minutes: 59));

    // Aplicar filtros
    final attendanceAsync = ref.watch(
      orgAdminAttendanceProvider(
        OrgAdminAttendanceFilter(
          startDate: _filters.startDate ?? startOfDay,
          endDate: _filters.endDate ?? endOfDay,
          userId: _filters.employeeId, // employeeId se usa como userId
          limit: 200,
        ),
      ),
    );

    // Filtrar en cliente (tipos, geocerca y sucursal)
    final filteredRecords = attendanceAsync.when(
      data: (records) {
        var filtered = records;

        // Filtrar por sucursal
        if (_filters.branchId != null) {
          filtered = filtered
              .where((r) => r.sucursalId == _filters.branchId)
              .toList();
        }

        // Filtrar por tipos
        if (_filters.types != null && _filters.types!.isNotEmpty) {
          filtered = filtered
              .where((r) => _filters.types!.contains(r.tipoRegistro))
              .toList();
        }

        // Filtrar por geocerca
        if (_filters.insideGeofence != null) {
          filtered = filtered
              .where(
                (r) =>
                    (r.estaDentroGeocerca ?? true) == _filters.insideGeofence,
              )
              .toList();
        }

        return filtered;
      },
      loading: () => <RegistrosAsistencia>[],
      error: (_, __) => <RegistrosAsistencia>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          // Badge de filtros activos
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtros avanzados',
                onPressed: _openFilters,
              ),
              if (_filters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(orgAdminAttendanceProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(orgAdminAttendanceProvider);
            await ref.read(
              orgAdminAttendanceProvider(
                OrgAdminAttendanceFilter(
                  startDate: startOfDay,
                  endDate: endOfDay,
                  limit: 200,
                ),
              ).future,
            );
          },
          child: attendanceAsync.when(
            data: (records) {
              // Calcular estadísticas con records filtrados
              final stats = _calculateStats(filteredRecords);

              if (filteredRecords.isEmpty) {
                return EmptyState(
                  icon: Icons.access_time_outlined,
                  title: 'Sin registros',
                  subtitle: _filters.hasActiveFilters
                      ? 'No hay registros que coincidan con los filtros'
                      : _selectedDate.day == now.day &&
                            _selectedDate.month == now.month &&
                            _selectedDate.year == now.year
                      ? 'No hay marcas de asistencia hoy'
                      : 'No hay marcas de asistencia en esta fecha',
                  primaryLabel: _filters.hasActiveFilters
                      ? 'Limpiar filtros'
                      : 'Cambiar fecha',
                  onPrimary: () {
                    if (_filters.hasActiveFilters) {
                      setState(() => _filters = const AttendanceFilters());
                    } else {
                      _selectDate(context);
                    }
                  },
                );
              }

              return CustomScrollView(
                slivers: [
                  // Selector de fecha
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _DateSelector(
                        selectedDate: _selectedDate,
                        onDateChanged: (date) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                    ),
                  ),

                  // Estadísticas
                  SliverToBoxAdapter(
                    child: AttendanceStatsSection(
                      total: stats.total,
                      valid: stats.valid,
                      outsideGeofence: stats.outsideGeofence,
                      errors: stats.errors,
                    ),
                  ),

                  // Header de lista
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Registros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${filteredRecords.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de registros
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final record = filteredRecords[index];
                        return AttendanceRecordCard(
                          record: record,
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AdminAttendanceRecordDetailSheet(
                                record: record,
                              ),
                            );
                          },
                        );
                      }, childCount: filteredRecords.length),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error cargando asistencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(orgAdminAttendanceProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceFilterSheet(
        initialFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryRed),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  _AttendanceStats _calculateStats(List<RegistrosAsistencia> records) {
    int total = records.length;
    int valid = 0;
    int outsideGeofence = 0;
    int errors = 0;

    for (final record in records) {
      final inside = record.estaDentroGeocerca ?? true;
      final legal = record.esValidoLegalmente ?? true;

      if (!inside) {
        outsideGeofence++;
      } else if (!legal) {
        errors++;
      } else {
        valid++;
      }
    }

    return _AttendanceStats(
      total: total,
      valid: valid,
      outsideGeofence: outsideGeofence,
      errors: errors,
    );
  }
}

// ============================================================================
// Widgets auxiliares
// ============================================================================

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        selectedDate.day == now.day &&
        selectedDate.month == now.month &&
        selectedDate.year == now.year;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryRed.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primaryRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Hoy' : _formatDate(selectedDate),
                  style: const TextStyle(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatLongDate(selectedDate),
                  style: TextStyle(
                    color: AppColors.neutral600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryRed,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            icon: const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.neutral700,
            ),
            tooltip: 'Cambiar fecha',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

// ============================================================================
// Modelos auxiliares
// ============================================================================

class _AttendanceStats {
  final int total;
  final int valid;
  final int outsideGeofence;
  final int errors;

  const _AttendanceStats({
    required this.total,
    required this.valid,
    required this.outsideGeofence,
    required this.errors,
  });
}
