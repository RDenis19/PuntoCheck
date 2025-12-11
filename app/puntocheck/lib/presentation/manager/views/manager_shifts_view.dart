import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ManagerShiftsViewState extends ConsumerState<ManagerShiftsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(managerTeamSchedulesProvider(null));

    // Filtrar localmente
    final filteredSchedules = schedulesAsync.valueOrNull?.where((s) {
      if (_searchQuery.isEmpty) return true;
      final profile = s['perfiles'] as Map<String, dynamic>;
      final fullName = '${profile['nombres']} ${profile['apellidos']}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios del Equipo'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(managerTeamSchedulesProvider(null));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: schedulesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
          data: (schedules) {
            final displayList = filteredSchedules ?? schedules;
            
            if (displayList.isEmpty) {
              return const EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Sin resultados',
                message: 'No se encontraron horarios con ese criterio.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = displayList[index];
                return InkWell(
                  onTap: () => _openAssignSheet(context, ref, schedule: schedule),
                  borderRadius: BorderRadius.circular(12),
                  child: _ScheduleCard(schedule: schedule),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAssignSheet(context, ref),
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openAssignSheet(BuildContext context, WidgetRef ref, {Map<String, dynamic>? schedule}) {
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
              _InfoItem(
                icon: Icons.access_time,
                label: 'Horario',
                value: '${template['hora_entrada']} - ${template['hora_salida']}',
              ),
              _InfoItem(
                icon: Icons.calendar_month,
                label: 'Vigencia',
                value: 'Desde: ${DateFormat('dd/MM/yyyy').format(startDate)}',
              ),
            ],
          ),
        ],
      ),

    );
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
