import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/models/turnos_jornada.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../widgets/manager_assign_schedule_sheet.dart';

class ManagerShiftsView extends ConsumerStatefulWidget {
  const ManagerShiftsView({super.key});

  @override
  ConsumerState<ManagerShiftsView> createState() => _ManagerShiftsViewState();
}

class _ManagerShiftsViewState extends ConsumerState<ManagerShiftsView>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (!mounted) return;
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(managerTeamSchedulesProvider(null));
    final templatesAsync = ref.watch(managerScheduleTemplatesProvider);

    // Filtrar localmente
    final filteredSchedules = schedulesAsync.valueOrNull?.where((s) {
      if (_searchQuery.isEmpty) return true;
      final profile = s['perfiles'] as Map<String, dynamic>;
      final fullName = '${profile['nombres']} ${profile['apellidos']}'
          .toLowerCase();
      final templateName = (s['plantillas_horarios'] as Map?)?['nombre']
          ?.toString()
          .toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) ||
          (templateName?.contains(query) ?? false);
    }).toList();

    final filteredTemplates = templatesAsync.valueOrNull?.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryRed,
                unselectedLabelColor: AppColors.neutral600,
                indicatorColor: AppColors.primaryRed,
                tabs: const [
                  Tab(text: 'Asignaciones'),
                  Tab(text: 'Plantillas'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: _tabIndex == 0
                        ? 'Buscar por empleado o plantilla...'
                        : 'Buscar por plantilla...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.neutral500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neutral300),
                    ),
                    filled: true,
                    fillColor: AppColors.neutral100,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabIndex == 0) {
                ref.invalidate(managerTeamSchedulesProvider(null));
              } else {
                ref.invalidate(managerScheduleTemplatesProvider);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            schedulesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (schedules) {
                final displayList = filteredSchedules ?? schedules;

                if (displayList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'Sin resultados',
                    message: 'No se encontraron asignaciones con ese criterio.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final schedule = displayList[index];
                    return InkWell(
                      onTap: () =>
                          _openAssignSheet(context, ref, schedule: schedule),
                      borderRadius: BorderRadius.circular(12),
                      child: _ScheduleCard(schedule: schedule),
                    );
                  },
                );
              },
            ),
            templatesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (templates) {
                final displayList = filteredTemplates ?? templates;

                if (displayList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.view_timeline_outlined,
                    title: 'Sin resultados',
                    message: 'No se encontraron plantillas con ese criterio.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = displayList[index];
                    return _TemplateCard(template: template);
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openAssignSheet(context, ref),
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _openAssignSheet(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? schedule,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManagerAssignScheduleSheet(
        existingSchedule: schedule,
        onAssigned: () {
          ref.invalidate(managerTeamSchedulesProvider(null));
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final profile = schedule['perfiles'] as Map<String, dynamic>;
    final template = schedule['plantillas_horarios'] as Map<String, dynamic>;
    final startDate = DateTime.parse(schedule['fecha_inicio']);
    final endDateStr = schedule['fecha_fin'];
    final endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;

    final isActive = endDate == null || endDate.isAfter(DateTime.now());
    final turnos =
        (template['turnos_jornada'] as List?)?.cast<dynamic>() ?? const [];
    final dias = (template['dias_laborales'] as List?)?.cast<dynamic>();
    final tolerancia = template['tolerancia_entrada_minutos'] ?? 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                child: Text(
                  profile['nombres'][0],
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['nombres']} ${profile['apellidos']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      template['nombre'],
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.successGreen.withValues(alpha: 0.1)
                      : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: isActive
                        ? AppColors.successGreen
                        : AppColors.neutral700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time,
                  label: 'Turnos',
                  value: _formatTurnosFromMap(turnos),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_month,
                  label: 'Vigencia',
                  value: 'Desde: ${DateFormat('dd/MM/yyyy').format(startDate)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.view_week_outlined,
                  label: 'Días',
                  value: _formatDiasLaboralesFromMap(dias),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer_outlined,
                  label: 'Tol.',
                  value: '${tolerancia}m',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDiasLaboralesFromMap(List<dynamic>? dias) {
    if (dias == null || dias.isEmpty) return '--';
    const names = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final mapped = dias
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .map((d) => names[d])
        .where((s) => s.isNotEmpty)
        .toList();
    return mapped.isEmpty ? '--' : mapped.join(', ');
  }

  static String _formatTurnosFromMap(List<dynamic> turnos) {
    if (turnos.isEmpty) return '--';
    final sorted = [...turnos]
      ..sort((a, b) {
        final ma = (a as Map?) ?? const {};
        final mb = (b as Map?) ?? const {};
        final oa = int.tryParse(ma['orden']?.toString() ?? '') ?? 0;
        final ob = int.tryParse(mb['orden']?.toString() ?? '') ?? 0;
        return oa.compareTo(ob);
      });

    return sorted
        .map((t) {
          final m = (t as Map?) ?? const {};
          final start = _formatTime(m['hora_inicio']?.toString());
          final end = _formatTime(m['hora_fin']?.toString());
          final nextDay = (m['es_dia_siguiente'] == true) ? ' (+1)' : '';
          return '$start-$end$nextDay';
        })
        .join(', ');
  }

  static String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PlantillasHorarios template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final dias = template.diasLaborales ?? const <int>[];
    final turnos = [...template.turnos]
      ..sort((a, b) {
        final oa = a.orden ?? 0;
        final ob = b.orden ?? 0;
        return oa.compareTo(ob);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (template.esRotativo == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Rotativo',
                    style: TextStyle(
                      color: AppColors.infoBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoItem(
            icon: Icons.view_week_outlined,
            label: 'Días',
            value: _formatDiasLaborales(dias),
          ),
          const SizedBox(height: 8),
          _InfoItem(
            icon: Icons.timer_outlined,
            label: 'Tolerancia',
            value: '${template.toleranciaEntradaMinutos ?? 10} min',
          ),
          const SizedBox(height: 8),
          _InfoItem(
            icon: Icons.access_time,
            label: 'Turnos',
            value: _formatTurnos(turnos),
          ),
        ],
      ),
    );
  }

  static String _formatDiasLaborales(List<int> dias) {
    if (dias.isEmpty) return '--';
    const names = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final mapped = dias
        .where((d) => d >= 1 && d <= 7)
        .map((d) => names[d])
        .where((s) => s.isNotEmpty)
        .toList();
    return mapped.isEmpty ? '--' : mapped.join(', ');
  }

  static String _formatTurnos(List<TurnosJornada> turnos) {
    if (turnos.isEmpty) return '--';
    return turnos
        .map((t) {
          final start = _formatTime(t.horaInicio);
          final end = _formatTime(t.horaFin);
          final nextDay = (t.esDiaSiguiente == true) ? ' (+1)' : '';
          return '$start-$end$nextDay';
        })
        .join(', ');
  }

  static String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}
