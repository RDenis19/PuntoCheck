import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                const Text(
                  'Horarios semanales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
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
            '${_dayLabel(schedule.dayOfWeek)} - ${schedule.startTime.substring(0, 5)} a ${schedule.endTime.substring(0, 5)}',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
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
                  '${schedule.startTime.substring(0, 5)} - ${schedule.endTime.substring(0, 5)}',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.schedule, color: AppColors.grey),
        ],
      ),
    );
  }
}

String _dayLabel(int dayOfWeek) {
  const days = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
  if (dayOfWeek < 0 || dayOfWeek >= days.length) return 'Dia';
  return days[dayOfWeek];
}
