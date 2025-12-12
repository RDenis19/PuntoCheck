import 'turnos_jornada.dart';

class PlantillasHorarios {
  final String id;
  final String organizacionId;
  final String nombre;
  // Compatibilidad: mantenemos campos básicos tomando el primer turno_jornada.
  final String? horaEntrada;
  final String? horaSalida;
  final int? tiempoDescansoMinutos;
  final List<int>? diasLaborales; // INT[]
  final bool? esRotativo;
  final bool? eliminado;
  final DateTime? creadoEn;
  final List<TurnosJornada> turnos;

  PlantillasHorarios({
    required this.id,
    required this.organizacionId,
    required this.nombre,
    this.horaEntrada,
    this.horaSalida,
    this.tiempoDescansoMinutos,
    this.diasLaborales,
    this.esRotativo,
    this.eliminado,
    this.creadoEn,
    this.turnos = const [],
  });

  factory PlantillasHorarios.fromJson(Map<String, dynamic> json) {
    final turnosJson = json['turnos_jornada'] as List?;
    final turnos = turnosJson != null
        ? turnosJson
            .map((e) => TurnosJornada.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TurnosJornada>[];

    final primerTurno = turnos.isNotEmpty ? turnos.first : null;

    return PlantillasHorarios(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      nombre: json['nombre'],
      horaEntrada: primerTurno?.horaInicio,
      horaSalida: primerTurno?.horaFin,
      tiempoDescansoMinutos: json['tolerancia_entrada_minutos'] ??
          json['tiempo_descanso_minutos'],
      diasLaborales: json['dias_laborales'] != null
          ? List<int>.from(json['dias_laborales'])
          : null,
      esRotativo: json['es_rotativo'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
      turnos: turnos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizacion_id': organizacionId,
        'nombre': nombre,
        'tolerancia_entrada_minutos': tiempoDescansoMinutos,
        'dias_laborales': diasLaborales,
        'es_rotativo': esRotativo,
        'eliminado': eliminado,
      };
}
