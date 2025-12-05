import '../models/solicitudes_permisos.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/banco_horas_compensatorias.dart';
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
    try {
      await supabase
          .from('solicitudes_permisos')
          .update({
            'estado': status.value,
            'aprobado_por_id': supabase.auth.currentUser!.id,
            'fecha_resolucion': DateTime.now().toIso8601String(),
            'comentario_resolucion': comment,
          })
          .eq('id', requestId);
    } catch (e) {
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

      final response = await query.order('fecha_deteccion', ascending: false);
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
        'fecha_origen': registro.fechaOrigen.toIso8601String(),
        'motivo': registro.motivo,
        'advertencia_legal_aceptada': registro.advertenciaLegalAceptada,
        // El usuario logueado es quien aprueba/registra la acción
        'aprobado_por_id': supabase.auth.currentUser!.id,
      };

      await supabase.from('banco_horas_compensatorias').insert(data);
    } catch (e) {
      throw Exception('Error modificando banco de horas: $e');
    }
  }

  /// Calcular saldo actual
  Future<double> getHoursBalance(String employeeId) async {
    try {
      final response = await supabase
          .from('banco_horas_compensatorias')
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
}
