import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/work_schedule_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class HorarioTrabajoView extends ConsumerWidget {
  const HorarioTrabajoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(myScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Horario de Trabajo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(myScheduleProvider),
            icon: const Icon(Icons.refresh),
            color: AppColors.backgroundDark,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: AppColors.backgroundDark.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay horarios asignados',
                    style: TextStyle(
                      color: AppColors.backgroundDark.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu administrador aun no ha configurado tu horario',
                    style: TextStyle(
                      color: AppColors.backgroundDark.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final todayIndex = DateTime.now().weekday % 7;
          final todayMatches =
              schedules.where((s) => s.dayOfWeek == todayIndex).toList();
          final WorkSchedule? todaySchedule =
              todayMatches.isNotEmpty ? todayMatches.first : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todaySchedule != null) ...[
                  _TodayScheduleBanner(schedule: todaySchedule),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    const Text(
                      'Horarios semanales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${schedules.length} dias',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.backgroundDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...schedules.map((schedule) => _ScheduleTile(schedule: schedule)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar el horario')),
      ),
    );
  }
}

class _TodayScheduleBanner extends StatelessWidget {
  const _TodayScheduleBanner({required this.schedule});

  final WorkSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDark,
            AppColors.black.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horario de hoy',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_dayLabel(schedule.dayOfWeek)} - ${_fmt(schedule.startTime)} a ${_fmt(schedule.endTime)}',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          _TypeChip(type: schedule.type, darkMode: true),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule});

  final WorkSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _dayLabel(schedule.dayOfWeek).substring(0, 3),
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayLabel(schedule.dayOfWeek),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(schedule.startTime)} - ${_fmt(schedule.endTime)}',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _TypeChip(type: schedule.type),
        ],
      ),
    );
  }
}

String _dayLabel(int dayOfWeek) {
  const days = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado'
  ];
  if (dayOfWeek < 0 || dayOfWeek >= days.length) return 'Dia';
  return days[dayOfWeek];
}

String _fmt(String hhmmss) => hhmmss.substring(0, 5);

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, this.darkMode = false});

  final ShiftCategory type;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig(type);
    final bg = darkMode
        ? Colors.white.withValues(alpha: 0.15)
        : config.color.withValues(alpha: 0.12);
    final fg = darkMode ? Colors.white : config.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCfg {
  const _TypeCfg(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_TypeCfg _typeConfig(ShiftCategory type) {
  switch (type) {
    case ShiftCategory.reducida:
      return _TypeCfg('Turno reducido', AppColors.infoBlue, Icons.timelapse);
    case ShiftCategory.corta:
      return _TypeCfg('Turno corto', AppColors.warningOrange, Icons.timer);
    case ShiftCategory.descanso:
      return _TypeCfg('Descanso', AppColors.successGreen, Icons.self_improvement);
    case ShiftCategory.completa:
    default:
      return _TypeCfg('Turno completo', AppColors.primaryRed, Icons.work_history);
  }
}
