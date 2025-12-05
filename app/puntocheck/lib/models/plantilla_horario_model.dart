class PlantillaHorarioModel {
  final String id;
  final String nombre;
  final String horaEntrada; // Formato "HH:MM:SS"
  final String horaSalida;
  final int tiempoDescansoMin;
  final List<int> diasLaborales; // [1, 2, 3, 4, 5]

  PlantillaHorarioModel({
    required this.id,
    required this.nombre,
    required this.horaEntrada,
    required this.horaSalida,
    required this.tiempoDescansoMin,
    required this.diasLaborales,
  });

  factory PlantillaHorarioModel.fromJson(Map<String, dynamic> json) {
    return PlantillaHorarioModel(
      id: json['id'],
      nombre: json['nombre'],
      horaEntrada: json['hora_entrada'],
      horaSalida: json['hora_salida'],
      tiempoDescansoMin: json['tiempo_descanso_min'],
      diasLaborales: List<int>.from(json['dias_laborales'] ?? []),
    );
  }
}
