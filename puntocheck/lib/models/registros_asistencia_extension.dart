// Extensión de Asistencia para RegistrosAsistencia.
//
// Provee utilidades para el modelo de asistencia, incluyendo:
// - Verificadores de tipo de marcación (entrada, salida, breaks)
// - Extractores de datos GPS
// - Propiedades de validación
// - Extensiones para listas de registros

import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/registros_asistencia.dart';

extension RegistrosAsistenciaX on RegistrosAsistencia {
  /// Determina si esta es una marcación de entrada
  bool get isEntrada => tipoRegistro == 'entrada';

  /// Determina si esta es una marcación de salida
  bool get isSalida => tipoRegistro == 'salida';

  /// Determina si esta es el inicio de un descanso
  bool get isInitBreak => tipoRegistro == 'inicio_break';

  /// Determina si esta es el fin de un descanso
  bool get isEndBreak => tipoRegistro == 'fin_break';

  /// Determina si fue registrada por GPS
  bool get wasViaGps => origen == OrigenMarcacion.gpsMovil;

  /// Determina si fue registrada por QR
  bool get wasViaQr => origen == OrigenMarcacion.qrFijo;

  /// Obtiene la latitud si existe dato GPS
  double? get latitud {
    if (ubicacionGps == null) return null;
    final coords = ubicacionGps!['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    return (coords[1] as num?)?.toDouble();
  }

  /// Obtiene la longitud si existe dato GPS
  double? get longitud {
    if (ubicacionGps == null) return null;
    final coords = ubicacionGps!['coordinates'] as List?;
    if (coords == null || coords.isEmpty) return null;
    return (coords[0] as num?)?.toDouble();
  }

  /// Obtiene el nombre completo del empleado
  String get empleadoNombre => perfilNombreCompleto;

  /// Obtiene texto descriptivo del tipo de registro
  String get tipoRegistroLabel {
    switch (tipoRegistro) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'inicio_break':
        return 'Inicio de descanso';
      case 'fin_break':
        return 'Fin de descanso';
      default:
        return tipoRegistro ?? 'Registro';
    }
  }

  /// Obtiene el icono para el tipo de registro
  String get tipoRegistroIcon {
    switch (tipoRegistro) {
      case 'entrada':
        return '🟢'; // Entrada (verde)
      case 'salida':
        return '🔴'; // Salida (rojo)
      case 'inicio_break':
        return '⏸️'; // Pausa
      case 'fin_break':
        return '▶️'; // Reanuda
      default:
        return '⚪';
    }
  }

  /// Valida si el registro tiene datos de GPS válidos
  bool get hasValidGpsData {
    if (latitud == null || longitud == null) return false;
    return latitud! >= -90 && latitud! <= 90 && longitud! >= -180 && longitud! <= 180;
  }

  /// Valida si tiene evidencia fotográfica
  bool get hasEvidence => evidenciaFotoUrl.isNotEmpty && evidenciaFotoUrl.trim() != 'null';

  /// Obtiene descripción corta para UI
  String get descripcionCorta {
    final tipo = tipoRegistroLabel;
    final hora = '${fechaHoraMarcacion.hour.toString().padLeft(2, '0')}:${fechaHoraMarcacion.minute.toString().padLeft(2, '0')}';
    return '$tipo a las $hora';
  }

  /// Calcula el estado de validez legal
  String get estadoValidezLabel {
    if (esValidoLegalmente == null) return 'No evaluado';
    if (esValidoLegalmente == true) return 'Válido';
    return 'Inválido';
  }
}

/// Extensión para listas de registros
extension RegistrosAsistenciaListX on List<RegistrosAsistencia> {
  /// Filtra solo las entradas del día
  List<RegistrosAsistencia> get soloEntradas =>
      where((r) => r.isEntrada).toList();

  /// Filtra solo las salidas del día
  List<RegistrosAsistencia> get soloSalidas => where((r) => r.isSalida).toList();

  /// Filtra solo las marcaciones dentro de geocerca
  List<RegistrosAsistencia> get dentroGeocerca =>
      where((r) => r.estaDentroGeocerca == true).toList();

  /// Filtra solo las marcaciones fuera de geocerca
  List<RegistrosAsistencia> get fueraGeocerca =>
      where((r) => r.estaDentroGeocerca == false).toList();

  /// Filtra registros con evidencia fotográfica
  List<RegistrosAsistencia> get conEvidencia =>
      where((r) => r.hasEvidence).toList();

  /// Ordena cronológicamente (más reciente primero)
  List<RegistrosAsistencia> get ordenadoPorFecha {
    final copy = toList();
    copy.sort((a, b) => b.fechaHoraMarcacion.compareTo(a.fechaHoraMarcacion));
    return copy;
  }

  /// Obtiene el primer registro del día (entrada)
  RegistrosAsistencia? get primerRegistroDelDia {
    if (isEmpty) return null;
    final sorted = toList();
    sorted.sort((a, b) => a.fechaHoraMarcacion.compareTo(b.fechaHoraMarcacion));
    return sorted.first;
  }

  /// Obtiene el último registro del día (salida)
  RegistrosAsistencia? get ultimoRegistroDelDia {
    if (isEmpty) return null;
    final sorted = toList();
    sorted.sort((a, b) => a.fechaHoraMarcacion.compareTo(b.fechaHoraMarcacion));
    return sorted.last;
  }

  /// Calcula horas trabajadas del día (aproximado)
  Duration get horasTrabajadasAproximada {
    final entrada = primerRegistroDelDia;
    final salida = ultimoRegistroDelDia;

    if (entrada == null || salida == null) return Duration.zero;
    if (entrada.isEntrada == false || salida.isSalida == false) {
      return Duration.zero;
    }

    var duracion = salida.fechaHoraMarcacion.difference(entrada.fechaHoraMarcacion);

    // Restar descansos
    for (int i = 0; i < length - 1; i++) {
      final actual = this[i];
      final siguiente = this[i + 1];

      if (actual.isInitBreak && siguiente.isEndBreak) {
        final tiempoDescanso =
            siguiente.fechaHoraMarcacion.difference(actual.fechaHoraMarcacion);
        duracion = duracion - tiempoDescanso;
      }
    }

    return duracion.isNegative ? Duration.zero : duracion;
  }
}
