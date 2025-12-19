import 'package:puntocheck/models/registros_asistencia.dart';

class AttendanceDaySummary {
  final DateTime day;
  final List<RegistrosAsistencia> records;
  final Duration workedNet;
  final Duration breakTotal;
  final bool isIncomplete;
  final bool hasGeofenceIssues;

  AttendanceDaySummary({
    required this.day,
    required this.records,
    required this.workedNet,
    required this.breakTotal,
    required this.isIncomplete,
    required this.hasGeofenceIssues,
  });

  DateTime get firstMark => records.isNotEmpty ? records.first.fechaHoraMarcacion : day;
  DateTime get lastMark => records.isNotEmpty ? records.last.fechaHoraMarcacion : day;
}

class AttendanceMonthSummary {
  final Duration workedNet;
  final Duration breakTotal;
  final int daysWithRecords;
  final int daysIncomplete;
  final int geofenceIssuesCount;

  AttendanceMonthSummary({
    required this.workedNet,
    required this.breakTotal,
    required this.daysWithRecords,
    required this.daysIncomplete,
    required this.geofenceIssuesCount,
  });
}

class AttendanceSummaryHelper {
  AttendanceSummaryHelper._();

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static List<AttendanceDaySummary> groupByDay(Iterable<RegistrosAsistencia> input) {
    final records = input.toList()
      ..sort((a, b) => a.fechaHoraMarcacion.compareTo(b.fechaHoraMarcacion));

    final Map<DateTime, List<RegistrosAsistencia>> byDay = {};
    for (final r in records) {
      final d = dateOnly(r.fechaHoraMarcacion);
      (byDay[d] ??= []).add(r);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a)); // newest first
    return [
      for (final day in days) _computeDay(day, byDay[day]!),
    ];
  }

  static AttendanceMonthSummary summarizeMonth(List<AttendanceDaySummary> days) {
    Duration worked = Duration.zero;
    Duration breaks = Duration.zero;
    var incomplete = 0;
    var geofenceIssues = 0;

    for (final d in days) {
      worked += d.workedNet;
      breaks += d.breakTotal;
      if (d.isIncomplete) incomplete += 1;
      if (d.hasGeofenceIssues) geofenceIssues += 1;
    }

    return AttendanceMonthSummary(
      workedNet: worked,
      breakTotal: breaks,
      daysWithRecords: days.length,
      daysIncomplete: incomplete,
      geofenceIssuesCount: geofenceIssues,
    );
  }

  static AttendanceDaySummary _computeDay(DateTime day, List<RegistrosAsistencia> records) {
    records.sort((a, b) => a.fechaHoraMarcacion.compareTo(b.fechaHoraMarcacion));

    DateTime? openWorkStart;
    DateTime? openBreakStart;
    Duration grossWork = Duration.zero;
    Duration breakTotal = Duration.zero;

    for (final r in records) {
      final tipo = (r.tipoRegistro ?? '').trim();
      final t = r.fechaHoraMarcacion;

      switch (tipo) {
        case 'entrada':
          openWorkStart ??= t;
          break;
        case 'salida':
          final start = openWorkStart;
          if (start != null && t.isAfter(start)) {
            grossWork += t.difference(start);
          }
          openWorkStart = null;
          openBreakStart = null;
          break;
        case 'inicio_break':
          openBreakStart ??= t;
          break;
        case 'fin_break':
          final start = openBreakStart;
          if (start != null && t.isAfter(start)) {
            breakTotal += t.difference(start);
          }
          openBreakStart = null;
          break;
        default:
          break;
      }
    }

    final isIncomplete = openWorkStart != null || openBreakStart != null;
    var workedNet = grossWork - breakTotal;
    if (workedNet.isNegative) workedNet = Duration.zero;

    final hasGeofenceIssues = records.any((r) => r.estaDentroGeocerca == false);

    return AttendanceDaySummary(
      day: day,
      records: records,
      workedNet: workedNet,
      breakTotal: breakTotal,
      isIncomplete: isIncomplete,
      hasGeofenceIssues: hasGeofenceIssues,
    );
  }
}
