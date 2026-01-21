import '../models/banco_horas_compensatorias.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/enums.dart';
import '../models/perfiles.dart';
import '../models/plantillas_horarios.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/sucursales.dart';
import 'supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) throw Exception('Perfil no encontrado');
      return Perfiles.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando perfil del manager: $e');
    }
  }

  Future<List<String>> _getManagedBranchIds() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from('encargados_sucursales')
        .select('sucursal_id, activo')
        .eq('manager_id', userId)
        .or('activo.is.null,activo.eq.true');

    return (response as List)
        .map((e) => (e as Map)['sucursal_id'] as String?)
        .whereType<String>()
        .toList();
  }

  // Sucursales asignadas -------------------------------------------------------
  Future<List<Sucursales>> getManagedBranches() async {
    try {
      final branchIds = await _getManagedBranchIds();
      if (branchIds.isEmpty) return const [];

      final response = await supabase
          .from('sucursales')
          .select(
            'id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros, tiene_qr_habilitado, eliminado, creado_en',
          )
          .inFilter('id', branchIds)
          .or('eliminado.is.null,eliminado.eq.false')
          .order('nombre', ascending: true);

      return (response as List).map((e) => Sucursales.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando sucursales asignadas: $e');
    }
  }

  // Equipo directo -----------------------------------------------------------
  Future<List<Perfiles>> getMyTeam({
    String? searchQuery,
    bool includeDeleted = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final branchIds = await _getManagedBranchIds();
      if (branchIds.isEmpty) return [];

      var query = supabase
          .from('perfiles')
          .select()
          .inFilter('sucursal_id', branchIds)
          .eq('rol', RolUsuario.employee.value)
          .neq('id', userId);

      if (!includeDeleted) {
        query = query.or('eliminado.is.null,eliminado.eq.false');
      }

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

      final branchIds = await _getManagedBranchIds();
      if (branchIds.isEmpty) return false;

      final response = await supabase
          .from('perfiles')
          .select('id')
          .eq('id', employeeId)
          .eq('rol', RolUsuario.employee.value)
          .inFilter('sucursal_id', branchIds)
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
          .select('''
            *,
            perfiles!inner(nombres, apellidos),
            sucursales(nombre),
            turnos_jornada(nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente)
          ''')
          .inFilter('perfil_id', teamIds)
          .eq('eliminado', false);

      if (employeeId != null) query = query.eq('perfil_id', employeeId);
      if (startDate != null) {
        query = query.gte('fecha_hora_marcacion', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('fecha_hora_marcacion', endDate.toIso8601String());
      }

      final response = await query
          .order('fecha_hora_marcacion', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => RegistrosAsistencia.fromDynamic(e))
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
          .select(
            '*, solicitante:perfiles!solicitudes_permisos_solicitante_id_fkey(nombres, apellidos)',
          )
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

      final request = await supabase
          .from('solicitudes_permisos')
          .select('id, solicitante_id, estado')
          .eq('id', requestId)
          .maybeSingle();

      if (request == null) throw Exception('Solicitud no encontrada');
      final employeeId = request['solicitante_id'] as String?;
      if (employeeId == null) throw Exception('Solicitud inválida');

      final belongs = await isEmployeeInMyTeam(employeeId);
      if (!belongs) {
        throw Exception('No puedes aprobar permisos fuera de tu sucursal');
      }

      final estado = request['estado']?.toString();
      if (estado != null && estado != EstadoAprobacion.pendiente.value) {
        throw Exception('Esta solicitud ya fue procesada');
      }

      await supabase
          .from('solicitudes_permisos')
          .update({
            'estado': EstadoAprobacion.aprobadoManager.value,
            'aprobado_por_id': userId,
            'fecha_resolucion': DateTime.now().toIso8601String(),
            'comentario_resolucion': (comment == null || comment.trim().isEmpty)
                ? 'Aprobado por el manager'
                : comment.trim(),
          })
          .eq('id', requestId);
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

      final request = await supabase
          .from('solicitudes_permisos')
          .select('id, solicitante_id, estado')
          .eq('id', requestId)
          .maybeSingle();

      if (request == null) throw Exception('Solicitud no encontrada');
      final employeeId = request['solicitante_id'] as String?;
      if (employeeId == null) throw Exception('Solicitud inválida');

      final belongs = await isEmployeeInMyTeam(employeeId);
      if (!belongs) {
        throw Exception('No puedes rechazar permisos fuera de tu sucursal');
      }

      final estado = request['estado']?.toString();
      if (estado != null && estado != EstadoAprobacion.pendiente.value) {
        throw Exception('Esta solicitud ya fue procesada');
      }

      final trimmedComment = comment.trim();
      if (trimmedComment.isEmpty) {
        throw Exception('Debes indicar un motivo de rechazo');
      }

      await supabase
          .from('solicitudes_permisos')
          .update({
            'estado': EstadoAprobacion.rechazado.value,
            'aprobado_por_id': userId,
            'fecha_resolucion': DateTime.now().toIso8601String(),
            'comentario_resolucion': trimmedComment,
          })
          .eq('id', requestId);
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

      final team = await getMyTeam(includeDeleted: true);
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
          .select('''
            id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
            turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
          ''')
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
        'fecha_inicio': DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).toIso8601String(),
        'fecha_fin': endDate != null
            ? DateTime(
                endDate.year,
                endDate.month,
                endDate.day,
              ).toIso8601String()
            : null,
      });
    } catch (e) {
      throw Exception('Error asignando horario: $e');
    }
  }

  Future<void> assignScheduleBulk({
    required List<String> employeeIds,
    required String templateId,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final profile = await getMyProfile();
    final orgId = profile.organizacionId;
    if (orgId == null) throw Exception('El manager no tiene organización');

    final team = await getMyTeam(includeDeleted: false);
    final allowedIds = team
        .where((p) => p.activo != false)
        .map((p) => p.id)
        .toSet();

    final uniqueIds = employeeIds.toSet().where((id) => id.trim().isNotEmpty);
    if (uniqueIds.isEmpty) throw Exception('Selecciona al menos un empleado');

    final invalid = uniqueIds.where((id) => !allowedIds.contains(id)).toList();
    if (invalid.isNotEmpty) {
      throw Exception('Hay empleados fuera de tu equipo');
    }

    final startIso = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String();

    final endIso = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day).toIso8601String()
        : null;

    final rows = uniqueIds
        .map(
          (employeeId) => <String, dynamic>{
            'perfil_id': employeeId,
            'organizacion_id': orgId,
            'plantilla_id': templateId,
            'fecha_inicio': startIso,
            'fecha_fin': endIso,
          },
        )
        .toList();

    // Inserta en batches para evitar payloads demasiado grandes.
    const batchSize = 75;
    try {
      for (var i = 0; i < rows.length; i += batchSize) {
        final end = (i + batchSize) > rows.length
            ? rows.length
            : (i + batchSize);
        await supabase
            .from('asignaciones_horarios')
            .insert(rows.sublist(i, end));
      }
    } catch (e) {
      throw Exception('Error asignando horario masivo: $e');
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
      final belongs = await isEmployeeInMyTeam(
        assignment['perfil_id'] as String,
      );
      if (!belongs) {
        throw Exception('No puedes editar asignaciones fuera de tu equipo');
      }

      await supabase
          .from('asignaciones_horarios')
          .update({
            'plantilla_id': templateId,
            'fecha_inicio': DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            ).toIso8601String(),
            'fecha_fin': endDate != null
                ? DateTime(
                    endDate.year,
                    endDate.month,
                    endDate.day,
                  ).toIso8601String()
                : null,
          })
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Error actualizando horario: $e');
    }
  }

  Future<void> deleteSchedule(String assignmentId) async {
    try {
      final assignment = await supabase
          .from('asignaciones_horarios')
          .select('perfil_id')
          .eq('id', assignmentId)
          .maybeSingle();

      if (assignment == null) throw Exception('Asignación no encontrada');
      // Opcional: Validar que pertenezca al equipo si es crítico,
      // aunque RLS debería encargarse, mejor ser seguros.
      final belongs = await isEmployeeInMyTeam(
        assignment['perfil_id'] as String,
      );
      if (!belongs) {
        throw Exception('No puedes eliminar asignaciones fuera de tu equipo');
      }

      await supabase
          .from('asignaciones_horarios')
          .delete()
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Error eliminando horario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeamSchedules({
    String? employeeId,
  }) async {
    try {
      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();
      if (teamIds.isEmpty) return [];

      var query = supabase
          .from('asignaciones_horarios')
          .select('''
            *,
            plantillas_horarios(
              id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
              turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
            ),
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

  Future<Map<String, dynamic>?> getEmployeeActiveSchedule(
    String employeeId,
  ) async {
    try {
      final belongs = await isEmployeeInMyTeam(employeeId);
      if (!belongs) throw Exception('El empleado no pertenece a tu equipo');

      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final response = await supabase
          .from('asignaciones_horarios')
          .select('''
            *,
            plantillas_horarios(
              id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
              turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
            )
          ''')
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

  // Alertas de cumplimiento --------------------------------------------------
  Future<List<AlertasCumplimiento>> getTeamComplianceAlerts({
    bool pendingOnly = false,
    int limit = 100,
    bool includeBranchOrphans = true,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final branchIds = await _getManagedBranchIds();
      if (branchIds.isEmpty) return const [];

      final profile = await getMyProfile();
      final orgId = profile.organizacionId;
      if (orgId == null || orgId.isEmpty) {
        throw Exception('No se pudo resolver la organización del manager');
      }

      // Alertas asociadas a empleados de las sucursales del manager.
      List<AlertasCumplimiento> alerts;
      try {
        var query = supabase
            .from('alertas_cumplimiento')
            .select(
              '*, empleado:perfiles!alertas_cumplimiento_empleado_id_fkey(nombres, apellidos, sucursal_id)',
            )
            .eq('organizacion_id', orgId)
            .inFilter('empleado.sucursal_id', branchIds);

        if (pendingOnly) query = query.eq('estado', 'pendiente');

        final response = await query
            .order('creado_en', ascending: false)
            .limit(limit);

        alerts = (response as List)
            .map((e) => AlertasCumplimiento.fromJson(e))
            .toList();
      } on PostgrestException {
        // Fallback: algunos setups no soportan filtrar por columna embebida.
        final team = await getMyTeam(includeDeleted: true);
        final teamIds = team.map((e) => e.id).toList();
        if (teamIds.isEmpty) return const [];

        var query = supabase
            .from('alertas_cumplimiento')
            .select(
              '*, empleado:perfiles!alertas_cumplimiento_empleado_id_fkey(nombres, apellidos, sucursal_id)',
            )
            .eq('organizacion_id', orgId)
            .inFilter('empleado_id', teamIds);

        if (pendingOnly) query = query.eq('estado', 'pendiente');

        final response = await query
            .order('creado_en', ascending: false)
            .limit(limit);

        alerts = (response as List)
            .map((e) => AlertasCumplimiento.fromJson(e))
            .toList();
      }

      if (!includeBranchOrphans) return alerts;

      // Algunas alertas pueden venir sin empleado_id (incidencias de configuraciones).
      // Las filtramos por sucursal_id dentro del JSON (si existe).
      final orphanResponse = await supabase
          .from('alertas_cumplimiento')
          .select()
          .eq('organizacion_id', orgId)
          .isFilter('empleado_id', null)
          .order('creado_en', ascending: false)
          .limit(limit);

      final orphanAlerts = (orphanResponse as List)
          .map((e) => AlertasCumplimiento.fromJson(e))
          .where((a) {
            final sid = a.detalleTecnico?['sucursal_id']?.toString();
            return sid != null && branchIds.contains(sid);
          })
          .toList();

      return [...alerts, ...orphanAlerts];
    } catch (e) {
      throw Exception('Error cargando alertas de cumplimiento: $e');
    }
  }

  Future<void> updateComplianceAlertStatus({
    required String alertId,
    required String status,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final result = await supabase
          .from('alertas_cumplimiento')
          .update({'estado': status})
          .eq('id', alertId)
          .select('id');

      final rows = List<Map<String, dynamic>>.from(result as List);
      if (rows.isEmpty) {
        throw Exception(
          'No se pudo actualizar la alerta. Verifica permisos o si todavía existe.',
        );
      }
    } catch (e) {
      throw Exception('Error actualizando estado de alerta: $e');
    }
  }
}
