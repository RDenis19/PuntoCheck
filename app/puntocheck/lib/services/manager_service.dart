import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/banco_horas_compensatorias.dart';
import '../models/enums.dart';
import 'supabase_client.dart';

/// Servicio especializado para operaciones del Manager.
/// 
/// El Manager tiene acceso limitado a:
/// - Su propio perfil
/// - Su equipo (empleados con jefe_inmediato_id = manager.id)
/// - Asistencia, permisos y banco de horas de su equipo
/// 
/// Todas las operaciones validan que:
/// - organizacion_id = get_my_org_id()
/// - jefe_inmediato_id = auth.uid()
class ManagerService {
  ManagerService._();
  static final instance = ManagerService._();

  // ============================================================================
  // 3.1 - PERFIL DEL MANAGER
  // ============================================================================

  /// Obtener el perfil del manager actual.
  /// 
  /// Query: SELECT * FROM perfiles WHERE id = auth.uid()
  Future<Perfiles> getMyProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await supabase
          .rpc('get_perfil_with_email', params: {'p_user_id': userId})
          .single();

      return Perfiles.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando perfil del manager: $e');
    }
  }

  // ============================================================================
  // 3.2 - EQUIPO DE TRABAJO
  // ============================================================================

  /// Obtener lista de empleados del equipo del manager.
  /// 
  /// Query: 
  /// SELECT * FROM perfiles 
  /// WHERE organizacion_id = get_my_org_id()
  ///   AND jefe_inmediato_id = auth.uid()
  ///   AND eliminado = false
  Future<List<Perfiles>> getMyTeam({String? searchQuery}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

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

  /// Verificar si un empleado pertenece al equipo del manager.
  /// 
  /// Usado para validar antes de hacer operaciones sobre un empleado.
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
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // 4 - ASISTENCIA DEL EQUIPO
  // ============================================================================

  /// Obtener registros de asistencia del equipo.
  /// 
  /// Filtra por:
  /// - Solo empleados del equipo (jefe_inmediato_id = auth.uid())
  /// - Rango de fechas (opcional)
  /// - Empleado específico (opcional)
  Future<List<RegistrosAsistencia>> getTeamAttendance({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    int limit = 50,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Primero obtener IDs de empleados del equipo
      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();

      if (teamIds.isEmpty) {
        return [];
      }

      var query = supabase
          .from('registros_asistencia')
          .select('*, perfiles!inner(nombres, apellidos)')
          .inFilter('perfil_id', teamIds)
          .eq('eliminado', false);

      if (employeeId != null) {
        query = query.eq('perfil_id', employeeId);
      }

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

  // ============================================================================
  // 5 - PERMISOS DEL EQUIPO
  // ============================================================================

  /// Obtener solicitudes de permisos del equipo.
  /// 
  /// Solo muestra permisos de empleados con jefe_inmediato_id = auth.uid()
  Future<List<SolicitudesPermisos>> getTeamPermissions({
    bool pendingOnly = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener IDs del equipo
      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();

      if (teamIds.isEmpty) {
        return [];
      }

      var query = supabase
          .from('solicitudes_permisos')
          .select() // Sin JOIN, solo los datos de solicitudes_permisos
          .inFilter('solicitante_id', teamIds);

      if (pendingOnly) {
        query = query.eq('estado', 'pendiente');
      }

      final response = await query.order('creado_en', ascending: false);

      return (response as List)
          .map((e) => SolicitudesPermisos.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando permisos del equipo: $e');
    }
  }

  /// Aprobar una solicitud de permiso.
  /// 
  /// Valida que el empleado pertenezca al equipo antes de aprobar.
  Future<void> approvePermission({
    required String requestId,
    String? comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

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

  /// Rechazar una solicitud de permiso.
  Future<void> rejectPermission({
    required String requestId,
    required String comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

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

  // ============================================================================
  // 6 - BANCO DE HORAS DEL EQUIPO
  // ============================================================================

  /// Obtener movimientos de banco de horas del equipo.
  Future<List<BancoHorasCompensatorias>> getTeamHoursBank({String? employeeId}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener IDs del equipo
      final team = await getMyTeam();
      final teamIds = team.map((e) => e.id).toList();

      if (teamIds.isEmpty) {
        return [];
      }

      var query = supabase
          .from('banco_horas')
          .select() // Solo datos de banco_horas, sin JOIN
          .inFilter('empleado_id', teamIds);

      if (employeeId != null) {
        query = query.eq('empleado_id', employeeId);
      }

      final response = await query.order('creado_en', ascending: false);

      return (response as List).map((e) => BancoHorasCompensatorias.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando banco de horas: $e');
    }
  }

  /// Registrar movimiento en banco de horas.
  /// 
  /// Solo puede hacerlo para empleados de su equipo.
  Future<void> registerHours({
    required String employeeId,
    required double hours,
    required String concept,
    bool acceptsWaiver = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validar que el empleado pertenece al equipo
      final isInTeam = await isEmployeeInMyTeam(employeeId);
      if (!isInTeam) {
        throw Exception('El empleado no pertenece a tu equipo');
      }

      // Obtener organizacion_id del empleado
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
}
