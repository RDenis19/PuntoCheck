import '../models/banco_horas_compensatorias.dart';
import '../models/enums.dart';
import '../models/perfiles.dart';
import '../models/plantillas_horarios.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import 'supabase_client.dart';

/// Servicio especializado para operaciones del Manager.
/// Mantiene todas las llamadas a Supabase separadas de la UI.
class ManagerService {
  ManagerService._();
  static final instance = ManagerService._();

  // Perfil del manager --------------------------------------------------------
  Future<Perfiles> getMyProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await supabase
          .rpc('get_perfil_with_email', params: {'p_user_id': userId})
          .single();
      return Perfiles.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando perfil del manager: $e');
    }
  }

  // Equipo directo -----------------------------------------------------------
  Future<List<Perfiles>> getMyTeam({String? searchQuery}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      var query = supabase
          .from('perfiles')
          .select()
          .eq('jefe_inmediato_id', userId)
          .eq('eliminado', false);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'apellidos.ilike.%$searchQuery%,nombres.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('apellidos', ascending: true);
      return (response as List).map((e) => Perfiles.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando equipo: $e');
    }
  }

  Future<bool> isEmployeeInMyTeam(String employeeId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await supabase
          .from('perfiles')
          .select('id')
          .eq('id', employeeId)
          .eq('jefe_inmediato_id', userId)
          .eq('eliminado', false)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  // Asistencia del equipo ----------------------------------------------------
  Future<List<RegistrosAsistencia>> getTeamAttendance({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    int limit = 50,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();
      if (teamIds.isEmpty) return [];

      var query = supabase
          .from('registros_asistencia')
          .select('*, perfiles!inner(nombres, apellidos)')
          .inFilter('perfil_id', teamIds)
          .eq('eliminado', false);

      if (employeeId != null) query = query.eq('perfil_id', employeeId);
      if (startDate != null) {
        query = query.gte('fecha_hora_marcacion', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('fecha_hora_marcacion', endDate.toIso8601String());
      }

      final response =
          await query.order('fecha_hora_marcacion', ascending: false).limit(limit);

      return (response as List)
          .map((e) => RegistrosAsistencia.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando asistencia del equipo: $e');
    }
  }

  // Permisos del equipo ------------------------------------------------------
  Future<List<SolicitudesPermisos>> getTeamPermissions({
    bool pendingOnly = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();
      if (teamIds.isEmpty) return [];

      var query = supabase
          .from('solicitudes_permisos')
          .select()
          .inFilter('solicitante_id', teamIds);

      if (pendingOnly) {
        query = query.eq('estado', EstadoAprobacion.pendiente.value);
      }

      final response = await query.order('creado_en', ascending: false);
      return (response as List)
          .map((e) => SolicitudesPermisos.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando permisos del equipo: $e');
    }
  }

  Future<void> approvePermission({
    required String requestId,
    String? comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await supabase.from('solicitudes_permisos').update({
        'estado': EstadoAprobacion.aprobadoManager.value,
        'aprobado_por_id': userId,
        'fecha_resolucion': DateTime.now().toIso8601String(),
        'comentario_resolucion': comment ?? 'Aprobado por el manager',
      }).eq('id', requestId);
    } catch (e) {
      throw Exception('Error aprobando permiso: $e');
    }
  }

  Future<void> rejectPermission({
    required String requestId,
    required String comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await supabase.from('solicitudes_permisos').update({
        'estado': EstadoAprobacion.rechazado.value,
        'aprobado_por_id': userId,
        'fecha_resolucion': DateTime.now().toIso8601String(),
        'comentario_resolucion': comment,
      }).eq('id', requestId);
    } catch (e) {
      throw Exception('Error rechazando permiso: $e');
    }
  }

  // Banco de horas -----------------------------------------------------------
  Future<List<BancoHorasCompensatorias>> getTeamHoursBank({
    String? employeeId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();
      if (teamIds.isEmpty) return [];

      var query = supabase
          .from('banco_horas')
          .select()
          .inFilter('empleado_id', teamIds);

      if (employeeId != null) {
        query = query.eq('empleado_id', employeeId);
      }

      final response = await query.order('creado_en', ascending: false);
      return (response as List)
          .map((e) => BancoHorasCompensatorias.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando banco de horas: $e');
    }
  }

  Future<void> registerHours({
    required String employeeId,
    required double hours,
    required String concept,
    bool acceptsWaiver = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final isInTeam = await isEmployeeInMyTeam(employeeId);
      if (!isInTeam) throw Exception('El empleado no pertenece a tu equipo');

      final employee = await supabase
          .from('perfiles')
          .select('organizacion_id')
          .eq('id', employeeId)
          .single();

      await supabase.from('banco_horas').insert({
        'organizacion_id': employee['organizacion_id'],
        'empleado_id': employeeId,
        'cantidad_horas': hours,
        'concepto': concept,
        'aprobado_por_id': userId,
        'acepta_renuncia_pago': acceptsWaiver,
      });
    } catch (e) {
      throw Exception('Error registrando horas: $e');
    }
  }

  // Notificaciones -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await supabase
          .from('notificaciones')
          .select()
          .eq('usuario_destino_id', userId)
          .order('creado_en', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error cargando notificaciones: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('id', notificationId)
          .eq('usuario_destino_id', userId);
    } catch (e) {
      throw Exception('Error marcando notificación: $e');
    }
  }

  // Plantillas / asignaciones de horarios ------------------------------------
  Future<List<PlantillasHorarios>> getScheduleTemplates() async {
    try {
      final profile = await getMyProfile();
      final orgId = profile.organizacionId;
      if (orgId == null) throw Exception('El manager no tiene organización');

      final response = await supabase
          .from('plantillas_horarios')
          .select()
          .eq('organizacion_id', orgId)
          .eq('eliminado', false)
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => PlantillasHorarios.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error cargando plantillas: $e');
    }
  }

  Future<void> assignSchedule({
    required String employeeId,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final profile = await getMyProfile();
    final orgId = profile.organizacionId;
    if (orgId == null) throw Exception('El manager no tiene organización');

    final belongs = await isEmployeeInMyTeam(employeeId);
    if (!belongs) throw Exception('El empleado no pertenece a tu equipo');

    try {
      await supabase.from('asignaciones_horarios').insert({
        'perfil_id': employeeId,
        'organizacion_id': orgId,
        'plantilla_id': templateId,
        'fecha_inicio':
            DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
        'fecha_fin': endDate != null
            ? DateTime(endDate.year, endDate.month, endDate.day).toIso8601String()
            : null,
      });
    } catch (e) {
      throw Exception('Error asignando horario: $e');
    }
  }

  Future<void> updateSchedule({
    required String assignmentId,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final assignment = await supabase
          .from('asignaciones_horarios')
          .select('perfil_id')
          .eq('id', assignmentId)
          .maybeSingle();

      if (assignment == null) throw Exception('Asignación no encontrada');
      final belongs = await isEmployeeInMyTeam(assignment['perfil_id'] as String);
      if (!belongs) throw Exception('No puedes editar asignaciones fuera de tu equipo');

      await supabase.from('asignaciones_horarios').update({
        'plantilla_id': templateId,
        'fecha_inicio':
            DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
        'fecha_fin': endDate != null
            ? DateTime(endDate.year, endDate.month, endDate.day).toIso8601String()
            : null,
      }).eq('id', assignmentId);
    } catch (e) {
      throw Exception('Error actualizando horario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeamSchedules({String? employeeId}) async {
    try {
      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();
      if (teamIds.isEmpty) return [];

      var query = supabase
          .from('asignaciones_horarios')
          .select('''
            *,
            plantillas_horarios(*),
            perfiles(nombres, apellidos)
          ''')
          .inFilter('perfil_id', teamIds);

      if (employeeId != null) {
        query = query.eq('perfil_id', employeeId);
      }

      final response = await query.order('fecha_inicio', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error obteniendo horarios del equipo: $e');
    }
  }

  Future<Map<String, dynamic>?> getEmployeeActiveSchedule(String employeeId) async {
    try {
      final belongs = await isEmployeeInMyTeam(employeeId);
      if (!belongs) throw Exception('El empleado no pertenece a tu equipo');

      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final response = await supabase
          .from('asignaciones_horarios')
          .select('*, plantillas_horarios(*)')
          .eq('perfil_id', employeeId)
          .lte('fecha_inicio', todayStr)
          .or('fecha_fin.is.null,fecha_fin.gte.$todayStr')
          .order('fecha_inicio', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Error obteniendo horario activo: $e');
    }
  }
}
