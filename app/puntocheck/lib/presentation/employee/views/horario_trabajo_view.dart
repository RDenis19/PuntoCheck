import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/employee/widgets/registro_widgets.dart';

class HorarioTrabajoView extends StatelessWidget {
  const HorarioTrabajoView({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Viernes, 31 de Octubre de 2025',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'En progreso',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // TODO(backend): la fecha y el estado (en progreso, pendiente, completado)
            // deben derivarse de los registros almacenados para personalizar la vista.
            Text(
              'Tu jornada actual está en marcha.',
              style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            const TodayScheduleCard(
              dateLabel: '31/10/2025',
              workedHours: '8h 00m',
              entryLabel: 'Entrada – Mañana',
              entryHour: '08:00 AM',
              exitLabel: 'Salida – Tarde',
              exitHour: '05:00 PM',
              totalHours: '9h 00m',
              breakTime: '1h 00m',
            ),
            const SizedBox(height: 24),
            WeekSummaryCard(
              dateRange: 'Oct 28 – Nov 03',
              daysWorked: 4,
              totalHours: '36h',
              averageHours: '9h',
              days: const [
                WeekSummaryDay(
                  label: 'Lun',
                  hours: '9h',
                  status: WeekDayStatus.worked,
                ),
                WeekSummaryDay(
                  label: 'Mar',
                  hours: '9h',
                  status: WeekDayStatus.worked,
                ),
                WeekSummaryDay(
                  label: 'Mié',
                  hours: '9h',
                  status: WeekDayStatus.worked,
                ),
                WeekSummaryDay(
                  label: 'Jue',
                  hours: '9h',
                  status: WeekDayStatus.worked,
                ),
                WeekSummaryDay(
                  label: 'Vie',
                  hours: '8h',
                  status: WeekDayStatus.current,
                ),
                WeekSummaryDay(label: 'Sáb', status: WeekDayStatus.off),
                WeekSummaryDay(label: 'Dom', status: WeekDayStatus.off),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


