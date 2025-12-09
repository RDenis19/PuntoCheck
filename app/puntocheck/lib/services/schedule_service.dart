import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/services/supabase_client.dart';

/// Servicio para gestión CRUD de plantillas de horarios
class ScheduleService {
  // Sin variable de instancia, usar supabase directamente

  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static ScheduleService get instance => _instance;

  /// Obtiene todas las plantillas de horarios de una organización
  Future<List<PlantillasHorarios>> getScheduleTemplates(
    String organizacionId,
  ) async {
    try {
      final response = await supabase
          .from('plantillas_horarios')
          .select()
          .eq('organizacion_id', organizacionId)
          .or('eliminado.is.null,eliminado.eq.false')
          .order('creado_en', ascending: false);

      return response.map((e) => PlantillasHorarios.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al obtener plantillas de horarios: $e');
    }
  }

  /// Crea una nueva plantilla de horario
  Future<PlantillasHorarios> createScheduleTemplate({
    required String organizacionId,
    required String nombre,
    required String horaEntrada, // "HH:mm" format
    required String horaSalida, // "HH:mm" format
    int tiempoDescansoMinutos = 60,
    List<int> diasLaborales = const [1, 2, 3, 4, 5],
    bool esRotativo = false,
  }) async {
    try {
      final response = await supabase
          .from('plantillas_horarios')
          .insert({
            'organizacion_id': organizacionId,
            'nombre': nombre,
            'hora_entrada': horaEntrada,
            'hora_salida': horaSalida,
            'tiempo_descanso_minutos': tiempoDescansoMinutos,
            'dias_laborales': diasLaborales,
            'es_rotativo': esRotativo,
            'eliminado': false,
          })
          .select()
          .single();

      return PlantillasHorarios.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear plantilla de horario: $e');
    }
  }

  /// Actualiza una plantilla de horario existente
  Future<void> updateScheduleTemplate({
    required String plantillaId,
    String? nombre,
    String? horaEntrada,
    String? horaSalida,
    int? tiempoDescansoMinutos,
    List<int>? diasLaborales,
    bool? esRotativo,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (nombre != null) updateData['nombre'] = nombre;
      if (horaEntrada != null) updateData['hora_entrada'] = horaEntrada;
      if (horaSalida != null) updateData['hora_salida'] = horaSalida;
      if (tiempoDescansoMinutos != null) {
        updateData['tiempo_descanso_minutos'] = tiempoDescansoMinutos;
      }
      if (diasLaborales != null) updateData['dias_laborales'] = diasLaborales;
      if (esRotativo != null) updateData['es_rotativo'] = esRotativo;

      if (updateData.isEmpty) return;

      await supabase
          .from('plantillas_horarios')
          .update(updateData)
          .eq('id', plantillaId);
    } catch (e) {
      throw Exception('Error al actualizar plantilla de horario: $e');
    }
  }

  /// Elimina (soft delete) una plantilla de horario
  Future<void> deleteScheduleTemplate(String plantillaId) async {
    try {
      await supabase
          .from('plantillas_horarios')
          .update({'eliminado': true}).eq('id', plantillaId);
    } catch (e) {
      throw Exception('Error al eliminar plantilla de horario: $e');
    }
  }

  /// Obtiene el número de empleados asignados a una plantilla
  Future<int> getAssignedEmployeesCount(String plantillaId) async {
    try {
      final response = await supabase
          .from('asignaciones_horarios')
          .select()
          .eq('plantilla_id', plantillaId)
          .or('fecha_fin.is.null,fecha_fin.gte.${DateTime.now().toIso8601String()}');

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar empleados asignados: $e');
    }
  }
}
