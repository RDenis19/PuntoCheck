import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import '../widgets/manager_assign_schedule_sheet.dart';

// Modelo local para agrupar asignaciones
class _ScheduleGroup {
  final String templateId;
  final String templateName;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic> templateData; // Para sacar turnos
  final List<Map<String, dynamic>> assignments; // Lista de perfiles asignados

  _ScheduleGroup({
    required this.templateId,
    required this.templateName,
    required this.startDate,
    this.endDate,
    required this.templateData,
    required this.assignments,
  });

  String get key =>
      '${templateId}_${startDate.toIso8601String()}_${endDate?.toIso8601String()}';
}

class ManagerShiftsView extends ConsumerStatefulWidget {
  const ManagerShiftsView({super.key});

  @override
  ConsumerState<ManagerShiftsView> createState() => _ManagerShiftsViewState();
}

class _ManagerShiftsViewState extends ConsumerState<ManagerShiftsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Lógica de agrupamiento
  List<_ScheduleGroup> _groupSchedules(List<Map<String, dynamic>> rawList) {
    final Map<String, _ScheduleGroup> groups = {};

    for (var item in rawList) {
      final tId = item['plantilla_id'] as String;
      final tMap = item['plantillas_horarios'] as Map<String, dynamic>;
      final tName = tMap['nombre'] as String;
      final start = DateTime.parse(item['fecha_inicio']);
      final endStr = item['fecha_fin'] as String?;
      final end = endStr != null ? DateTime.parse(endStr) : null;

      // Clave única
      final key = '${tId}_${start.toIso8601String()}_$endStr';

      if (!groups.containsKey(key)) {
        groups[key] = _ScheduleGroup(
          templateId: tId,
          templateName: tName,
          startDate: start,
          endDate: end,
          templateData: tMap,
          assignments: [],
        );
      }
      groups[key]!.assignments.add(item);
    }

    // Convertir a lista y ordenar por fecha inicio desc
    final list = groups.values.toList();
    list.sort(
      (a, b) => b.startDate.compareTo(a.startDate),
    ); // Más reciente arriba
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(managerTeamSchedulesProvider(null));
    final templatesAsync = ref.watch(managerScheduleTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.secondaryWhite,
      appBar: AppBar(
        title: const Text('Horarios y Turnos'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        titleSpacing: 20,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.neutral900,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.neutral900,
                  unselectedLabelColor: AppColors.neutral500,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Asignaciones'),
                    Tab(text: 'Plantillas'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: _tabIndex == 0
                        ? 'Buscar por plantilla...'
                        : 'Buscar plantilla...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.neutral500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(managerTeamSchedulesProvider(null));
              ref.invalidate(managerScheduleTemplatesProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ASIGNACIONES AGRUPADAS
          schedulesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rawList) {
              // 1. Agrupar
              final groups = _groupSchedules(rawList);

              // 2. Filtrar grupos por nombre de plantilla (Búsqueda básica)
              final filtered = groups.where((g) {
                if (_searchQuery.isEmpty) return true;
                return g.templateName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.calendar_today_rounded,
                  title: 'Sin asignaciones',
                  message: 'No hay horarios asignados.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final group = filtered[index];
                  return _GroupedScheduleCard(
                    group: group,
                    onTap: () => _showGroupDetail(context, group),
                  );
                },
              );
            },
          ),

          // TAB 2: PLANTILLAS (Sin cambios mayores, solo visual)
          templatesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (templates) {
              final filtered = templates.where((t) {
                if (_searchQuery.isEmpty) return true;
                return t.nombre.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.view_timeline_rounded,
                  title: 'Sin plantillas',
                  message: 'No se encontraron plantillas.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _TemplateCard(template: filtered[index]);
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ManagerAssignScheduleSheet(
                    onAssigned: () =>
                        ref.invalidate(managerTeamSchedulesProvider(null)),
                  ),
                );
              },
              backgroundColor: AppColors.primaryRed,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Asignar Masivo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // Modal para ver miembros del grupo y eliminar individualmente
  void _showGroupDetail(BuildContext context, _ScheduleGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupDetailSheet(group: group),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS
// -----------------------------------------------------------------------------

class _GroupedScheduleCard extends StatelessWidget {
  final _ScheduleGroup group;
  final VoidCallback onTap;

  const _GroupedScheduleCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final turnos =
        (group.templateData['turnos_jornada'] as List?)?.cast<dynamic>() ??
        const [];
    // Convertir turnos a visual blocks
    final parsedTurnos = turnos.map((t) {
      final m = t as Map;
      return _TimeBlock(
        start: m['hora_inicio']?.toString() ?? '00:00:00',
        end: m['hora_fin']?.toString() ?? '00:00:00',
      );
    }).toList();

    final count = group.assignments.length;
    final startStr = DateFormat('d MMM').format(group.startDate);
    final endStr = group.endDate != null
        ? DateFormat('d MMM yyyy').format(group.endDate!)
        : 'Indefinido';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Título y Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.templateName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.neutral900,
                        ),
                      ),
                      Text(
                        '$startStr - $endStr',
                        style: const TextStyle(
                          color: AppColors.neutral500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline
            _VisualTimeline(blocks: parsedTurnos),

            // Hint
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Toca para ver empleados',
                style: TextStyle(fontSize: 11, color: AppColors.neutral400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupDetailSheet extends ConsumerWidget {
  final _ScheduleGroup group;
  const _GroupDetailSheet({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            group.templateName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${group.assignments.length} Empleados Asignados',
            style: const TextStyle(color: AppColors.neutral500),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: group.assignments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = group.assignments[index];
                final profile = item['perfiles'] as Map<String, dynamic>;
                final name = '${profile['nombres']} ${profile['apellidos']}';
                final pid = item['id']; // Assignment ID

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.neutral100,
                    child: Text(
                      profile['nombres'][0],
                      style: const TextStyle(color: AppColors.neutral900),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.errorRed,
                    ),
                    onPressed: () async {
                      // Eliminar individual
                      try {
                        await ref
                            .read(managerScheduleControllerProvider.notifier)
                            .deleteSchedule(pid);

                        if (!context.mounted) return;

                        // Cerrar modal
                        Navigator.pop(context);
                        ref.invalidate(managerTeamSchedulesProvider(null));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Turno eliminado')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final dynamic template; // PlantillasHorarios object
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final turnosList = template.turnos as List;
    final parsedTurnos = turnosList.map((t) {
      return _TimeBlock(
        start: t.horaInicio ?? '00:00:00',
        end: t.horaFin ?? '00:00:00',
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                template.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.neutral900,
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _VisualTimeline(blocks: parsedTurnos, compact: true),
        ],
      ),
    );
  }
}

// --- VISUAL TIMELINE REUSED ---
class _TimeBlock {
  final String start;
  final String end;
  _TimeBlock({required this.start, required this.end});
  double get startHour => _parseHour(start);
  double get endHour => _parseHour(end);
  double _parseHour(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h + (m / 60.0);
  }
}

class _VisualTimeline extends StatelessWidget {
  final List<_TimeBlock> blocks;
  final bool compact;
  const _VisualTimeline({required this.blocks, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    double minH = 6.0;
    double maxH = 22.0;

    for (var b in blocks) {
      if (b.startHour < minH) minH = b.startHour.floorToDouble();
      if (b.endHour > maxH) maxH = b.endHour.ceilToDouble();
    }
    minH = (minH - 1).clamp(0, 24);
    maxH = (maxH + 1).clamp(0, 24);
    final totalHours = maxH - minH;
    if (totalHours <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          height: compact ? 12 : 24,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ...blocks.map((b) {
                final startRel = (b.startHour - minH).clamp(0, totalHours);
                final duration = (b.endHour - b.startHour);
                final leftPercent = startRel / totalHours;
                final widthPercent = duration / totalHours;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Positioned(
                      left: width * leftPercent,
                      width: width * widthPercent,
                      top: compact ? 2 : 4,
                      bottom: compact ? 2 : 4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryRed, Color(0xFFE53935)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(compact ? 4 : 6),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatHour(minH),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral500,
                  ),
                ),
                Text(
                  _formatHour(maxH),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatHour(double h) {
    final hour = h.floor();
    final min = ((h - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }
}
