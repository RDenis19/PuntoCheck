import 'package:puntocheck/models/asignaciones_horarios.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';

/// DTO sencillo para exponer la asignación y su plantilla asociada.
class EmployeeSchedule {
  EmployeeSchedule({
    required this.asignacion,
    required this.plantilla,
  });

  final AsignacionesHorarios asignacion;
  final PlantillasHorarios plantilla;
}

