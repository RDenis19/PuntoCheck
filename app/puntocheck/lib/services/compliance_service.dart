import '../models/solicitudes_permisos.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/banco_horas_compensatorias.dart';
import '../models/notificacion.dart';
import '../models/auditoria_log.dart';
import '../models/enums.dart';
import 'supabase_client.dart';

class ComplianceService {
  ComplianceService._();
  static final instance = ComplianceService._();

  // ---------------------------------------------------------------------------
  // SOLICITUDES DE PERMISOS
  // ---------------------------------------------------------------------------

  /// Crear solicitud (Employee)
  Future<void> createRequest(SolicitudesPermisos solicitud) async {
    try {
      // Construimos el mapa manualmente para evitar enviar 'id' o 'creado_en'
      // y asegurarnos de enviar el valor del Enum correctamente.
      final data = {
        'organizacion_id': solicitud.organizacionId,
        'solicitante_id': supabase.auth.currentUser!.id,
        'tipo': solicitud.tipo.value, // Enum -> String
        'fecha_inicio': solicitud.fechaInicio.toIso8601String(),
        'fecha_fin': solicitud.fechaFin.toIso8601String(),
        'dias_totales': solicitud.diasTotales,
        'motivo_detalle': solicitud.motivoDetalle,
        'documento_soporte_url': solicitud.documentoSoporteUrl,
        'estado': EstadoAprobacion.pendiente.value, // Forzamos estado inicial
      };

      await supabase.from('solicitudes_permisos').insert(data);
    } catch (e) {
      throw Exception('Error creando solicitud: $e');
    }
  }

  /// Obtener solicitudes
  Future<List<SolicitudesPermisos>> getRequests({
    bool pendingOnly = false,
    bool myRequests = false,
  }) async {
    try {
      // Usamos var para el builder
      var query = supabase.from('solicitudes_permisos').select();

      if (myRequests) {
        query = query.eq('solicitante_id', supabase.auth.currentUser!.id);
      }
      if (pendingOnly) {
        query = query.eq('estado', EstadoAprobacion.pendiente.value);
      }

      final response = await query.order('creado_en', ascending: false);
      return (response as List)
          .map((e) => SolicitudesPermisos.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando solicitudes: $e');
    }
  }

  /// Resolver Solicitud (Aprobar/Rechazar)
  Future<void> resolveRequest({
    required String requestId,
    required EstadoAprobacion status,
    String? comment,
  }) async {
    print('📝 ComplianceService.resolveRequest iniciado');
    print('📝 Request ID: $requestId');
    print('📝 Status: ${status.value}');
    print('📝 Comment: ${comment ?? "null"}');
    print('📝 User ID: ${supabase.auth.currentUser?.id}');
    
    try {
      final updateData = {
        'estado': status.value,
        'aprobado_por_id': supabase.auth.currentUser!.id,
        'fecha_resolucion': DateTime.now().toIso8601String(),
        'comentario_resolucion': comment,
      };
      
      print('📝 Update data: $updateData');
      
      final result = await supabase
          .from('solicitudes_permisos')
          .update(updateData)
          .eq('id', requestId)
          .select();
      
      print('✅ Resultado: $result');
      print('✅ Solicitud resuelta');
    } catch (e, stackTrace) {
      print('❌ ERROR: $e');
      print('❌ Stack: $stackTrace');
      throw Exception('Error resolviendo solicitud: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ALERTAS DE CUMPLIMIENTO
  // ---------------------------------------------------------------------------

  Future<List<AlertasCumplimiento>> getAlerts(
    String orgId, {
    bool onlyPending = true,
  }) async {
    try {
      var query = supabase
          .from('alertas_cumplimiento')
          .select()
          .eq('organizacion_id', orgId);

      if (onlyPending) {
        query = query.eq('estado', 'pendiente');
      }

      // La tabla no tiene columna fecha_deteccion según el esquema; usamos creado_en.
      final response = await query.order('creado_en', ascending: false);
      return (response as List)
          .map((e) => AlertasCumplimiento.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando alertas: $e');
    }
  }

  Future<void> justifyAlert(String alertId, String justification) async {
    try {
      await supabase
          .from('alertas_cumplimiento')
          .update({
            'estado': 'justificado',
            'justificacion_admin': justification,
            'atendido_por_id': supabase.auth.currentUser!.id,
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
    } catch (e) {
      throw Exception('Error justificando alerta: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // BANCO DE HORAS
  // ---------------------------------------------------------------------------

  /// Agregar registro al banco (Compensación o Gasto)
  Future<void> addHourRecord(BancoHorasCompensatorias registro) async {
    try {
      // Mapeo manual para inserción limpia
      final data = {
        'organizacion_id': registro.organizacionId,
        'empleado_id': registro.empleadoId,
        'cantidad_horas': registro.cantidadHoras,
        'concepto': registro.concepto,
        'acepta_renuncia_pago': registro.aceptaRenunciaPago,
        // El usuario logueado es quien aprueba/registra la acción
        'aprobado_por_id': supabase.auth.currentUser!.id,
      };

      await supabase.from('banco_horas').insert(data);
    } catch (e) {
      throw Exception('Error modificando banco de horas: $e');
    }
  }

  /// Calcular saldo actual
  Future<double> getHoursBalance(String employeeId) async {
    try {
      final response = await supabase
          .from('banco_horas')
          .select('cantidad_horas')
          .eq('empleado_id', employeeId);

      final list = response as List;
      if (list.isEmpty) return 0.0;

      double total = 0.0;
      for (var item in list) {
        total += (item['cantidad_horas'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception('Error calculando saldo: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // RESOLVER ALERTA (Cambiar estado)
  // ---------------------------------------------------------------------------

  /// Resolver alerta con estado y justificación
  Future<void> resolveAlert({
    required String alertId,
    required String newStatus,
    String? justification,
  }) async {
    try {
      await supabase.from('alertas_cumplimiento').update({
        'estado': newStatus,
        'justificacion_auditor': justification,
      }).eq('id', alertId);
    } catch (e) {
      throw Exception('Error resolviendo alerta: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICACIONES
  // ---------------------------------------------------------------------------

  /// Obtener notificaciones del usuario
  Future<List<Notificacion>> getNotifications(String userId) async {
    try {
      final response = await supabase
          .from('notificaciones')
          .select()
          .eq('usuario_destino_id', userId)
          .order('creado_en', ascending: false)
          .limit(50);

      return (response as List)
          .map((e) => Notificacion.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando notificaciones: $e');
    }
  }

  /// Marcar notificación como leída
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Error marcando notificación: $e');
    }
  }

  /// Obtener conteo de notificaciones no leídas
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await supabase
          .from('notificaciones')
          .select('id')
          .eq('usuario_destino_id', userId)
          .eq('leido', false)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Error contando notificaciones: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // AUDITORÍA
  // ---------------------------------------------------------------------------

  /// Obtener logs de auditoría
  Future<List<AuditoriaLog>> getAuditLog({
    String? orgId,
    String? actorId,
    String? tabla,
    int limit = 100,
  }) async {
    try {
      var query = supabase.from('auditoria_log').select();

      if (orgId != null) {
        query = query.eq('organizacion_id', orgId);
      }
      if (actorId != null) {
        query = query.eq('actor_id', actorId);
      }
      if (tabla != null) {
        query = query.eq('tabla_afectada', tabla);
      }

      final response = await query
          .order('creado_en', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => AuditoriaLog.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando auditoría: $e');
    }
  }
}
