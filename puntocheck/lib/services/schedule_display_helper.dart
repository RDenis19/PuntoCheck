import 'package:flutter/material.dart';

import '../models/plantillas_horarios.dart';
import '../models/turnos_jornada.dart';
import '../utils/theme/app_colors.dart';

class ScheduleDisplayHelper {
  ScheduleDisplayHelper._();

  static String formatHm(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 5) return trimmed.substring(0, 5);
    return trimmed;
  }

  static List<TurnosJornada> sortedTurns(PlantillasHorarios plantilla) {
    final turns = [...plantilla.turnos];
    turns.sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));
    return turns;
  }

  static String formatTurnsSegments(Iterable<TurnosJornada> turns) {
    final segments = turns.map((t) {
      final start = formatHm(t.horaInicio);
      final end = formatHm(t.horaFin);
      final suffix = (t.esDiaSiguiente == true) ? ' (+1)' : '';
      return '$start–$end$suffix';
    }).toList();

    return segments.isEmpty ? '--' : segments.join(' y ');
  }

  static String formatTemplateSummary(PlantillasHorarios plantilla) {
    final turns = sortedTurns(plantilla);
    if (turns.isNotEmpty) return formatTurnsSegments(turns);

    final start = plantilla.horaEntrada != null ? formatHm(plantilla.horaEntrada!) : '--';
    final end = plantilla.horaSalida != null ? formatHm(plantilla.horaSalida!) : '--';
    return '$start–$end';
  }

  static String weekdayShortEs(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'L';
      case DateTime.tuesday:
        return 'M';
      case DateTime.wednesday:
        return 'Mi';
      case DateTime.thursday:
        return 'J';
      case DateTime.friday:
        return 'V';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'D';
      default:
        return '?';
    }
  }

  static List<int> normalizedLaborDays(List<int>? raw) {
    final days = raw ?? const <int>[];
    return days
        .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
        .toSet()
        .toList()
      ..sort();
  }

  static List<Widget> buildWeekdayChips({
    required List<int>? diasLaborales,
  }) {
    final active = normalizedLaborDays(diasLaborales).toSet();
    return List<Widget>.generate(7, (index) {
      final weekday = index + 1;
      final isActive = active.contains(weekday);
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(weekdayShortEs(weekday)),
          backgroundColor: isActive
              ? AppColors.primaryRed.withValues(alpha: 0.10)
              : AppColors.neutral100,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.primaryRed : AppColors.neutral600,
          ),
          side: BorderSide(
            color: isActive
                ? AppColors.primaryRed.withValues(alpha: 0.35)
                : AppColors.neutral200,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        ),
      );
    });
  }
}
