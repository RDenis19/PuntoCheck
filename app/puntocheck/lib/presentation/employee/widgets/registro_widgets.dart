import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class RegistroCircleAction extends StatelessWidget {
  const RegistroCircleAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.primaryRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.white, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class RegistroLocationCard extends StatelessWidget {
  const RegistroLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(backend): los datos de ubicación, coordenadas, hora y estado del GPS deben sincronizarse
    // con el servicio de localización del dispositivo y almacenarse para evidencia auditada.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ubicación actual',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'GPS Activo',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Dirección',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Loja Av. 18 Noviembre, Mercadillo',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _RegistroDetailTile(
                  title: 'Coordenadas',
                  subtitle: 'Lat: -3.8915\nLong: -79.2046',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RegistroDetailTile(
                  title: 'Hora',
                  subtitle: 'Hora: 12:20\nFecha: 31-oct.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vista de mapa (mock)')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Toca para ver el mapa',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayScheduleCard extends StatelessWidget {
  const TodayScheduleCard({
    super.key,
    required this.dateLabel,
    required this.workedHours,
    required this.entryLabel,
    required this.entryHour,
    required this.exitLabel,
    required this.exitHour,
    required this.totalHours,
    required this.breakTime,
  });

  final String dateLabel;
  final String workedHours;
  final String entryLabel;
  final String entryHour;
  final String exitLabel;
  final String exitHour;
  final String totalHours;
  final String breakTime;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): los datos de entrada/salida y acumulados deben venir de la asistencia real
    // para reflejar el progreso exacto del día.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrada de hoy',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    workedHours,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Horas trabajadas',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ScheduleSlot(
                  label: entryLabel,
                  value: entryHour,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScheduleSlot(
                  label: exitLabel,
                  value: exitHour,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ScheduleDetail(label: 'Total', value: totalHours),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScheduleDetail(label: 'Descanso', value: breakTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeekSummaryDay {
  const WeekSummaryDay({required this.label, this.hours, required this.status});

  final String label;
  final String? hours;
  final WeekDayStatus status;
}

enum WeekDayStatus { worked, current, off }

class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({
    super.key,
    required this.dateRange,
    required this.days,
    required this.daysWorked,
    required this.totalHours,
    required this.averageHours,
  });

  final String dateRange;
  final List<WeekSummaryDay> days;
  final int daysWorked;
  final String totalHours;
  final String averageHours;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): este resumen debe provenir de un endpoint semanal que consolide asistencias
    // (días trabajados, horas totales y promedio de la semana).
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: AppColors.primaryRed.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Semana Actual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ],
              ),
              Text(
                dateRange,
                style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) => _WeekDayChip(day: day)).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Días trabajados',
                  value: '$daysWorked',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(label: 'Total horas', value: totalHours),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(label: 'Promedio', value: averageHours),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegistroDetailTile extends StatelessWidget {
  const _RegistroDetailTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSlot extends StatelessWidget {
  const _ScheduleSlot({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              color == AppColors.successGreen ? Icons.login : Icons.logout,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({required this.day});

  final WeekSummaryDay day;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor;

    switch (day.status) {
      case WeekDayStatus.worked:
        background = AppColors.successGreen.withValues(alpha: 0.18);
        textColor = AppColors.successGreen;
        break;
      case WeekDayStatus.current:
        background = AppColors.primaryRed.withValues(alpha: 0.18);
        textColor = AppColors.primaryRed;
        break;
      case WeekDayStatus.off:
        background = AppColors.grey.withValues(alpha: 0.15);
        textColor = AppColors.grey;
        break;
    }

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            day.label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day.hours ?? '--',
          style: TextStyle(
            color: day.hours != null
                ? AppColors.black.withValues(alpha: 0.7)
                : AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.black.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.backgroundDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
