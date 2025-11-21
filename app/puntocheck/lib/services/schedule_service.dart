import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_schedule_model.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene mi horario semanal
  Future<List<WorkSchedule>> getMySchedule() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Prioridad: Horario específico del usuario.
      // Si no hay, la UI/Lógica debería buscar el horario general (user_id is null).
      // Aquí traemos AMBOS y la lógica de negocio (o el backend) decide cuál aplica.
      // Por simplicidad, traemos todo lo que RLS me permite ver.
      final response = await _supabase
          .from('work_schedules')
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .order('day_of_week', ascending: true);

      return (response as List)
          .map((e) => WorkSchedule.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando horarios: $e');
    }
  }

  /// ADMIN: Asigna horario a un empleado
  Future<void> createSchedule(WorkSchedule schedule) async {
    // Mapear modelo a JSON, excluyendo ID si es nuevo
    final data = {
        'organization_id': schedule.organizationId,
        'user_id': schedule.userId,
        'day_of_week': schedule.dayOfWeek,
        'start_time': schedule.startTime,
        'end_time': schedule.endTime,
        'type': schedule.type.toJson(),
    };
    
    await _supabase.from('work_schedules').insert(data);
  }
}