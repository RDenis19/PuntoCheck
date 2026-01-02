import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/attendance_stats_card.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_attendance_filter_sheet.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_attendance_record_card.dart';
import 'package:puntocheck/presentation/shared/models/attendance_filters.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/storage_object_image.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de asistencia del equipo del manager (Fase 2).
///
/// Permite al manager:
/// - Ver historial de asistencia de su equipo
/// - Filtrar por empleado, rango de fechas, sucursal y tipo
/// - Ver quién marcó dentro/fuera de geocerca
/// - Ver estadísticas de asistencia
class ManagerAttendanceView extends ConsumerStatefulWidget {
  const ManagerAttendanceView({super.key});

  @override
  ConsumerState<ManagerAttendanceView> createState() =>
      _ManagerAttendanceViewState();
}

class _ManagerAttendanceViewState extends ConsumerState<ManagerAttendanceView> {
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

    final schedulesAsync = ref.watch(managerTeamSchedulesProvider(null));

    // Obtener registros de asistencia con filtros
    final attendanceAsync = ref.watch(
      managerTeamAttendanceProvider(
        ManagerAttendanceFilter(
          startDate: _filters.startDate ?? startOfDay,
          endDate: _filters.endDate ?? endOfDay,
          employeeId: _filters.employeeId,
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
      body: SafeArea(
        child: Column(
          children: [
            // Header Manual (Tipo Admin/Auditor) para evitar crashes y unificar estilo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lado Izquierdo (Filtros)
                  SizedBox(
                    width: 96,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded),
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
                  ),
                  // Centro (Título)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Asistencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                  ),
                  // Lado Derecho (Refrescar)
                  SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Actualizar',
                          onPressed: () {
                            ref.invalidate(managerTeamAttendanceProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(managerTeamAttendanceProvider);
                },
                color: AppColors.primaryRed,
                child: attendanceAsync.when(
                  data: (records) {
                    // Calcular estadísticas con records filtrados
                    final scheduleAssignments =
                        schedulesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
                    final insights = _computeInsights(
                      records: filteredRecords,
                      scheduleAssignments: scheduleAssignments,
                    );

                    if (filteredRecords.isEmpty) {
                      return EmptyState(
                        icon: Icons.access_time_outlined,
                        title: 'Sin registros',
                        message: _filters.hasActiveFilters
                            ? 'No hay registros que coincidan con los filtros'
                            : _selectedDate.day == now.day &&
                                  _selectedDate.month == now.month &&
                                  _selectedDate.year == now.year
                            ? 'No hay marcas de asistencia hoy'
                            : 'No hay marcas de asistencia en esta fecha',
                        actionLabel: _filters.hasActiveFilters
                            ? 'Limpiar filtros'
                            : 'Cambiar fecha',
                        onAction: () {
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

                        // Estadísticas (Resumen Rojo)
                        SliverToBoxAdapter(
                          child: _ManagerAttendanceStatsSection(insights: insights),
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
                              final dateKey = _dateKey(record.fechaHoraMarcacion);
                              final missingExit = insights.missingExitEmployeeDateKeys
                                  .contains('${record.perfilId}::$dateKey');
                              final isLate = insights.lateRecordIds.contains(
                                record.id,
                              );
                              return ManagerAttendanceRecordCard(
                                record: record,
                                isLate: isLate,
                                missingExit: missingExit,
                                onViewEvidence: record.evidenciaFotoUrl.trim().isEmpty
                                    ? null
                                    : () => _openEvidence(context, record),
                                onTap: () {
                                  _openDetail(context, record);
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
                              ref.invalidate(managerTeamAttendanceProvider);
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
          ],
        ),
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManagerAttendanceFilterSheet(
        initialFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
        },
      ),
    );
  }

  void _openEvidence(BuildContext context, RegistrosAsistencia record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: StorageObjectImage(
                  bucketId: 'evidencias',
                  pathOrUrl: record.evidenciaFotoUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, RegistrosAsistencia record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AttendanceDetailSheet(record: record),
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

  static _AttendanceInsights _computeInsights({
    required List<RegistrosAsistencia> records,
    required List<Map<String, dynamic>> scheduleAssignments,
  }) {
    final lateRecordIds = <String>{};
    final missingExitEmployeeDateKeys = <String>{};

    int insideGeofence = 0;
    int outsideGeofence = 0;
    int mockGps = 0;

    final assignmentsByEmployee = <String, List<Map<String, dynamic>>>{};
    for (final assignment in scheduleAssignments) {
      final employeeId = assignment['perfil_id']?.toString();
      if (employeeId == null) continue;
      (assignmentsByEmployee[employeeId] ??= []).add(assignment);
    }
    for (final list in assignmentsByEmployee.values) {
      list.sort((a, b) {
        final da =
            DateTime.tryParse(a['fecha_inicio']?.toString() ?? '') ??
            DateTime(1970);
        final db =
            DateTime.tryParse(b['fecha_inicio']?.toString() ?? '') ??
            DateTime(1970);
        return db.compareTo(da);
      });
    }

    final dayTypesByEmployeeDate = <String, Set<String>>{};

    for (final record in records) {
      final inside = record.estaDentroGeocerca ?? true;
      if (inside) {
        insideGeofence++;
      } else {
        outsideGeofence++;
      }
      if (record.esMockLocation == true) mockGps++;

      final dateKey = _dateKey(record.fechaHoraMarcacion);
      final employeeDayKey = '${record.perfilId}::$dateKey';
      (dayTypesByEmployeeDate[employeeDayKey] ??= <String>{}).add(
        record.tipoRegistro ?? '',
      );

      if (record.tipoRegistro == 'entrada') {
        final rule = _resolveScheduleRule(
          employeeId: record.perfilId,
          date: record.fechaHoraMarcacion,
          assignmentsByEmployee: assignmentsByEmployee,
        );
        if (rule != null && record.fechaHoraMarcacion.isAfter(rule.lateAfter)) {
          lateRecordIds.add(record.id);
        }
      }
    }

    for (final entry in dayTypesByEmployeeDate.entries) {
      final types = entry.value;
      if (types.contains('entrada') && !types.contains('salida')) {
        missingExitEmployeeDateKeys.add(entry.key);
      }
    }

    return _AttendanceInsights(
      total: records.length,
      insideGeofence: insideGeofence,
      outsideGeofence: outsideGeofence,
      mockGps: mockGps,
      lateRecordIds: lateRecordIds,
      missingExitEmployeeDateKeys: missingExitEmployeeDateKeys,
    );
  }

  static _ScheduleRule? _resolveScheduleRule({
    required String employeeId,
    required DateTime date,
    required Map<String, List<Map<String, dynamic>>> assignmentsByEmployee,
  }) {
    final assignments = assignmentsByEmployee[employeeId];
    if (assignments == null || assignments.isEmpty) return null;

    final day = DateTime(date.year, date.month, date.day);

    Map<String, dynamic>? active;
    for (final a in assignments) {
      final start = DateTime.tryParse(a['fecha_inicio']?.toString() ?? '');
      if (start == null) continue;
      final startDay = DateTime(start.year, start.month, start.day);
      if (day.isBefore(startDay)) continue;

      final endRaw = a['fecha_fin']?.toString();
      if (endRaw != null) {
        final end = DateTime.tryParse(endRaw);
        if (end != null) {
          final endDay = DateTime(end.year, end.month, end.day);
          if (day.isAfter(endDay)) continue;
        }
      }

      active = a;
      break;
    }

    if (active == null) return null;

    final template = active['plantillas_horarios'];
    if (template is! Map) return null;
    final templateMap = Map<String, dynamic>.from(template);

    final tolerance =
        int.tryParse(
          templateMap['tolerancia_entrada_minutos']?.toString() ?? '',
        ) ??
        10;

    final turnos =
        (templateMap['turnos_jornada'] as List?)?.cast<dynamic>() ?? const [];
    if (turnos.isEmpty) return null;

    final sorted = [...turnos]
      ..sort((a, b) {
        final ma = (a as Map?) ?? const {};
        final mb = (b as Map?) ?? const {};
        final oa = int.tryParse(ma['orden']?.toString() ?? '') ?? 0;
        final ob = int.tryParse(mb['orden']?.toString() ?? '') ?? 0;
        return oa.compareTo(ob);
      });

    final first = (sorted.first as Map?) ?? const {};
    final startStr = first['hora_inicio']?.toString();
    if (startStr == null || startStr.isEmpty) return null;
    final startTime = _parseTime(startStr);
    if (startTime == null) return null;

    final startDateTime = DateTime(
      day.year,
      day.month,
      day.day,
      startTime.hour,
      startTime.minute,
    );

    return _ScheduleRule(
      lateAfter: startDateTime.add(Duration(minutes: tolerance)),
    );
  }

  static _ParsedTime? _parseTime(String raw) {
    final text = raw.trim();
    if (text.length < 4) return null;
    final normalized = text.length >= 5 ? text.substring(0, 5) : text;
    final parts = normalized.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return _ParsedTime(hour: h, minute: m);
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primaryRed,
            size: 24,
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
                  style: const TextStyle(
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
            icon: const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryRed),
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

class _AttendanceInsights {
  final int total;
  final int insideGeofence;
  final int outsideGeofence;
  final int mockGps;
  final Set<String> lateRecordIds;
  final Set<String> missingExitEmployeeDateKeys;

  const _AttendanceInsights({
    required this.total,
    required this.insideGeofence,
    required this.outsideGeofence,
    required this.mockGps,
    required this.lateRecordIds,
    required this.missingExitEmployeeDateKeys,
  });
}

class _ScheduleRule {
  final DateTime lateAfter;

  const _ScheduleRule({required this.lateAfter});
}

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime({required this.hour, required this.minute});
}

/// Header con Resumen Rojo (Nuevo diseño solicitado)
class _ManagerAttendanceStatsSection extends StatelessWidget {
  final _AttendanceInsights insights;

  const _ManagerAttendanceStatsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Total Marcas', value: '${insights.total}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _StatItem(label: 'En Sitio', value: '${insights.insideGeofence}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _StatItem(label: 'Fuera Sitio', value: '${insights.outsideGeofence}'),
            ],
          ),
          // Si hay Mock GPS, mostramos alerta
          if (insights.mockGps > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${insights.mockGps} Alertas de GPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Botón "Ver más"
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => _AttendanceInsightsSheet(insights: insights),
              ),
              icon: const Icon(Icons.tune, size: 16, color: Colors.white70),
              label: const Text('Detalles', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _AttendanceInsightsSheet extends StatelessWidget {
  final _AttendanceInsights insights;

  const _AttendanceInsightsSheet({required this.insights});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores Detallados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 14),
            _InsightTile(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warningOrange,
              title: 'Fuera de geocerca',
              value: '${insights.outsideGeofence}',
              subtitle: 'Marcaciones fuera del radio configurado.',
            ),
            _InsightTile(
              icon: Icons.location_off_outlined,
              color: AppColors.warningOrange,
              title: 'GPS (Alerta)',
              value: '${insights.mockGps}',
              subtitle: 'Ubicación simulada detectada.',
            ),
            _InsightTile(
              icon: Icons.schedule_outlined,
              color: AppColors.warningOrange,
              title: 'Entradas tarde',
              value: '${insights.lateRecordIds.length}',
              subtitle: 'Superan la tolerancia del horario.',
            ),
            _InsightTile(
              icon: Icons.logout_outlined,
              color: AppColors.errorRed,
              title: 'Faltas de salida',
              value: '${insights.missingExitEmployeeDateKeys.length}',
              subtitle: 'Entrada sin salida registrada.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _InsightTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDetailSheet extends StatelessWidget {
  final RegistrosAsistencia record;

  const _AttendanceDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.perfilNombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),
              _DetailRow(label: 'Tipo', value: record.tipoRegistro ?? '--'),
              _DetailRow(
                label: 'Fecha/hora',
                value: record.fechaHoraMarcacion.toIso8601String(),
              ),
              _DetailRow(
                label: 'Geocerca',
                value: (record.estaDentroGeocerca ?? true) ? 'Dentro' : 'Fuera',
              ),
              _DetailRow(
                label: 'GPS',
                value: record.esMockLocation == true ? 'Simulado (Alerta)' : 'Normal',
              ),
              if (record.turnoNombreTurno != null)
                _DetailRow(label: 'Turno', value: record.turnoNombreTurno!),
              if (record.notasSistema != null &&
                  record.notasSistema!.trim().isNotEmpty)
                _DetailRow(label: 'Notas', value: record.notasSistema!.trim()),
              if (record.evidenciaFotoUrl.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: StorageObjectImage(
                              bucketId: 'evidencias',
                              pathOrUrl: record.evidenciaFotoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Ver evidencia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.neutral900),
            ),
          ),
        ],
      ),
    );
  }
}
