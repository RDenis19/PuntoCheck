class PlantillasHorarios {
  final String id;
  final String organizacionId;
  final String nombre;
  final String horaEntrada; // TIME se maneja como String "HH:mm:ss"
  final String horaSalida;
  final int? tiempoDescansoMinutos;
  final List<int>? diasLaborales; // INT[]
  final bool? esRotativo;
  final bool? eliminado;
  final DateTime? creadoEn;

  PlantillasHorarios({
    required this.id,
    required this.organizacionId,
    required this.nombre,
    required this.horaEntrada,
    required this.horaSalida,
    this.tiempoDescansoMinutos,
    this.diasLaborales,
    this.esRotativo,
    this.eliminado,
    this.creadoEn,
  });

  factory PlantillasHorarios.fromJson(Map<String, dynamic> json) {
    return PlantillasHorarios(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      nombre: json['nombre'],
      horaEntrada: json['hora_entrada'],
      horaSalida: json['hora_salida'],
      tiempoDescansoMinutos: json['tiempo_descanso_minutos'],
      diasLaborales: json['dias_laborales'] != null
          ? List<int>.from(json['dias_laborales'])
          : null,
      esRotativo: json['es_rotativo'],
      eliminado: json['eliminado'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizacion_id': organizacionId,
    'nombre': nombre,
    'hora_entrada': horaEntrada,
    'hora_salida': horaSalida,
    'tiempo_descanso_minutos': tiempoDescansoMinutos,
    'dias_laborales': diasLaborales,
    'es_rotativo': esRotativo,
    'eliminado': eliminado,
  };
}
