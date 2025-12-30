// Helper para lógica de asistencia.
//
// Centraliza validaciones, cálculos y reglas de negocio para el módulo de asistencia.
// Proporciona métodos estáticos para:
// - Validación de secuencia de tipos de marcación
// - Cálculo de rangos de turno
// - Verificación de tolerancias de entrada
// - Detección de geofence

import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';

/// Resultado de validación de tipo de registro permitido
class TypeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> allowedTypes;

  TypeValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.allowedTypes,
  });
}

/// Rango de horarios de trabajo
class ShiftRange {
  final DateTime start;
  final DateTime end;
  final bool endsNextDay;

  ShiftRange({
    required this.start,
    required this.end,
    required this.endsNextDay,
  });

  bool isWithinShift(DateTime dateTime) {
    if (endsNextDay) {
      // Si la jornada cruza medianoche
      return dateTime.isAfter(start) || dateTime.isBefore(end);
    } else {
      return dateTime.isAfter(start) && dateTime.isBefore(end);
    }
  }

  Duration get duration => end.difference(start);
}

/// Helper estático para validaciones de asistencia
class AttendanceHelper {
  AttendanceHelper._();

  /// Determina si dos fechas son del mismo día
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Obtiene los tipos de registro permitidos según el último registro
  /// Aplica la lógica de secuencia: entrada -> salida/break -> salida -> entrada (nuevo día)
  static List<String> getAllowedTypes(
    RegistrosAsistencia? lastRecord,
    DateTime now,
  ) {
    const validSequence = <String, List<String>>{
      'entrada': ['inicio_break', 'salida'],
      'inicio_break': ['fin_break'],
      'fin_break': ['inicio_break', 'salida'],
      'salida': ['entrada'],
    };

    if (lastRecord == null) {
      return const ['entrada'];
    }

    // Si la última marcación no es del mismo día, se permite nueva entrada
    if (!isSameDay(lastRecord.fechaHoraMarcacion, now)) {
      return const ['entrada'];
    }

    final lastType = lastRecord.tipoRegistro;
    if (lastType == null || lastType.trim().isEmpty) {
      return const ['entrada'];
    }

    return validSequence[lastType] ?? const ['entrada'];
  }

  /// Valida si el tipo de registro seleccionado está permitido
  static TypeValidationResult validateRegistroType(
    String selectedType,
    RegistrosAsistencia? lastRecord,
    DateTime now,
  ) {
    final allowedTypes = getAllowedTypes(lastRecord, now);

    if (!allowedTypes.contains(selectedType)) {
      String? errorMsg;
      if (lastRecord == null) {
        errorMsg = 'Primero debes registrar tu entrada.';
      } else if (!isSameDay(lastRecord.fechaHoraMarcacion, now)) {
        errorMsg = 'Primero registra la entrada de hoy.';
      } else {
        switch (lastRecord.tipoRegistro) {
          case 'entrada':
            errorMsg = selectedType == 'entrada'
                ? 'Ya registraste la entrada hoy.'
                : 'Primero inicia el descanso o registra tu salida.';
            break;
          case 'inicio_break':
            errorMsg =
                'Primero debes terminar el descanso antes de continuar.';
            break;
          case 'fin_break':
            errorMsg = 'Ya terminaste el descanso. Registra tu salida.';
            break;
          case 'salida':
            errorMsg = selectedType == 'entrada'
                ? null
                : 'Primero registra la entrada de hoy.';
            break;
          default:
            errorMsg = 'Estado de asistencia no reconocido.';
        }
      }
      return TypeValidationResult(
        isValid: false,
        errorMessage: errorMsg ?? 'Tipo de registro no permitido.',
        allowedTypes: allowedTypes,
      );
    }

    return TypeValidationResult(
      isValid: true,
      allowedTypes: allowedTypes,
    );
  }

  /// Obtiene el siguiente tipo de registro lógico en la secuencia
  static String getNextType(String currentType) {
    switch (currentType) {
      case 'entrada':
        return 'salida';
      case 'inicio_break':
        return 'fin_break';
      case 'fin_break':
        return 'salida';
      case 'salida':
        return 'entrada';
      default:
        return 'entrada';
    }
  }

  /// Calcula el rango de horas del turno
  static ShiftRange? computeShiftRange(PlantillasHorarios? plantilla) {
    if (plantilla == null) return null;

    final turnos = [...plantilla.turnos]
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));

    final startStr = turnos.isNotEmpty
        ? turnos.first.horaInicio
        : plantilla.horaEntrada;
    final endStr =
        turnos.isNotEmpty ? turnos.last.horaFin : plantilla.horaSalida;

    final startTod = _parseTimeOfDay(startStr);
    final endTod = _parseTimeOfDay(endStr);

    if (startTod == null || endTod == null) return null;

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      startTod.hour,
      startTod.minute,
    );

    var end = DateTime(
      now.year,
      now.month,
      now.day,
      endTod.hour,
      endTod.minute,
    );

    final endsNextDayExplicit =
        turnos.isNotEmpty && (turnos.last.esDiaSiguiente == true);
    final endsNextDay = endsNextDayExplicit || end.isBefore(start);

    if (endsNextDay) {
      end = end.add(const Duration(days: 1));
    }

    return ShiftRange(start: start, end: end, endsNextDay: endsNextDay);
  }

  /// Determina el `turno_jornada_id` para una marcación en base a los turnos de la plantilla.
  ///
  /// Retorna `null` si no hay turnos o no se puede determinar un match.
  static String? resolveTurnoJornadaId(DateTime now, PlantillasHorarios? plantilla) {
    if (plantilla == null) return null;
    final turnos = [...plantilla.turnos]
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));
    if (turnos.isEmpty) return null;

    DateTime? toDateTimeToday(String hhmm) {
      final tod = _parseTimeOfDay(hhmm);
      if (tod == null) return null;
      return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    }

    bool inRange(DateTime dt, DateTime start, DateTime end, {required bool crossesMidnight}) {
      if (!crossesMidnight) {
        return !dt.isBefore(start) && !dt.isAfter(end);
      }
      // Jornada cruzando medianoche: dt >= start OR dt <= end (del día siguiente).
      return !dt.isBefore(start) || !dt.isAfter(end);
    }

    for (final t in turnos) {
      final start = toDateTimeToday(t.horaInicio);
      final endBase = toDateTimeToday(t.horaFin);
      if (start == null || endBase == null) continue;

      var end = endBase;
      final crossesMidnight = (t.esDiaSiguiente == true) || end.isBefore(start);
      if (crossesMidnight) {
        end = end.add(const Duration(days: 1));
      }

      if (inRange(now, start, end, crossesMidnight: crossesMidnight)) {
        return t.id;
      }
    }

    // Fallback: si no match, usamos el primer turno (mejor que null en entornos simples).
    return turnos.first.id;
  }

  /// Calcula la hora límite para entrada (con tolerancia)
  static DateTime? computeLatestEntryTime(
    PlantillasHorarios? plantilla,
    int toleranceMinutes,
  ) {
    if (plantilla == null) return null;

    final turnos = [...plantilla.turnos]
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));

    final startStr = turnos.isNotEmpty
        ? turnos.first.horaInicio
        : plantilla.horaEntrada;
    final startTod = _parseTimeOfDay(startStr);

    if (startTod == null) return null;

    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day, startTod.hour, startTod.minute);

    return start.add(Duration(minutes: toleranceMinutes));
  }

  /// Validación de geofence (distancia)
  static bool isWithinGeofence(double distance, double radiusMeters) {
    return distance <= radiusMeters;
  }

  /// Obtiene color para tipo de registro
  static String getTypeColor(String type) {
    switch (type) {
      case 'entrada':
        return '#10B981'; // Green
      case 'salida':
        return '#EF4444'; // Red
      case 'inicio_break':
      case 'fin_break':
        return '#F59E0B'; // Amber
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Obtiene etiqueta legible para tipo
  static String getTypeLabel(String type) {
    switch (type) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'inicio_break':
        return 'Inicio descanso';
      case 'fin_break':
        return 'Fin descanso';
      default:
        return type;
    }
  }

  /// Parse time string "HH:mm" to TimeOfDay equivalent
  static TimeOfDayValue? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDayValue(hour: h, minute: m);
  }
}

/// Simple time of day representation
class TimeOfDayValue {
  final int hour;
  final int minute;

  TimeOfDayValue({required this.hour, required this.minute});

  @override
  String toString() => '$hour:${minute.toString().padLeft(2, '0')}';
}
