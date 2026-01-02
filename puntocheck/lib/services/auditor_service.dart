import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/auditoria_log.dart';
import '../models/auditor_attendance_entry.dart';
import '../models/enums.dart';
import '../models/notificacion.dart';
import '../models/sucursales.dart';
import 'storage_service.dart';
import 'supabase_client.dart';

/// Servicio dedicado al rol Auditor.
///
/// En general: mucho READ, poco WRITE (solo validaciones como notas/estado).
class AuditorService {
  AuditorService._();
  static final instance = AuditorService._();

  Future<List<Sucursales>> getOrganizationBranches({
    required String orgId,
    bool includeDeleted = false,
  }) async {
    try {
      var query = supabase
          .from('sucursales')
          .select(
            'id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros, tiene_qr_habilitado, eliminado, creado_en',
          )
          .eq('organizacion_id', orgId);

      if (!includeDeleted) {
        query = query.or('eliminado.is.null,eliminado.eq.false');
      }

      final response = await query.order('nombre', ascending: true);
      return (response as List).map((e) => Sucursales.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando sucursales: $e');
    }
  }

  Future<List<AuditorAttendanceEntry>> getAttendanceRecords({
    required String orgId,
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    String? employeeQuery,
    bool onlyGeofenceIssues = false,
    bool onlyMockLocation = false,
    int limit = 300,
  }) async {
    try {
      var query = supabase
          .from('registros_asistencia')
          .select('''
            id, perfil_id, organizacion_id, sucursal_id, tipo_registro,
            fecha_hora_marcacion, fecha_hora_servidor, ubicacion_gps, precision_metros,
            esta_dentro_geocerca, es_mock_location, evidencia_foto_url, origen, notas,
            eliminado, creado_en,
            perfiles!inner(id, organizacion_id, nombres, apellidos, cedula, rol, sucursal_id),
            sucursales(id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros),
            turnos_jornada(nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente)
          ''')
          .eq('organizacion_id', orgId)
          .or('eliminado.is.null,eliminado.eq.false');

      if (branchId != null && branchId.isNotEmpty) {
        query = query.eq('sucursal_id', branchId);
      }

      if (startDate != null) {
        query = query.gte('fecha_hora_marcacion', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('fecha_hora_marcacion', endDate.toIso8601String());
      }

      if (onlyGeofenceIssues) {
        query = query.eq('esta_dentro_geocerca', false);
      }

      if (onlyMockLocation) {
        query = query.eq('es_mock_location', true);
      }

      final q = employeeQuery?.trim();
      if (q != null && q.isNotEmpty) {
        // Nota: `foreignTable` requiere `perfiles!inner` en el select.
        query = query.or(
          'nombres.ilike.%$q%,apellidos.ilike.%$q%,cedula.ilike.%$q%',
          referencedTable: 'perfiles',
        );
      }

      final response = await query
          .order('fecha_hora_marcacion', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => AuditorAttendanceEntry.fromDynamic(e))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error consultando asistencia: ${e.message}');
    } catch (e) {
      throw Exception('Error consultando asistencia: $e');
    }
  }

  Future<AuditorAttendanceEntry> getAttendanceRecordById(String recordId) async {
    try {
      final response = await supabase
          .from('registros_asistencia')
          .select('''
            id, perfil_id, organizacion_id, sucursal_id, tipo_registro,
            fecha_hora_marcacion, fecha_hora_servidor, ubicacion_gps, precision_metros,
            esta_dentro_geocerca, es_mock_location, evidencia_foto_url, origen, notas,
            eliminado, creado_en,
            perfiles(id, organizacion_id, nombres, apellidos, cedula, rol, sucursal_id),
            sucursales(id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros),
            turnos_jornada(nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente)
          ''')
          .eq('id', recordId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Registro no encontrado o sin permisos.');
      }

      return AuditorAttendanceEntry.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Error cargando registro: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando registro: $e');
    }
  }

  Future<void> updateAttendanceNotes({
    required String recordId,
    required String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{'notas': notes};
      await supabase.from('registros_asistencia').update(payload).eq(
            'id',
            recordId,
          );
    } on PostgrestException catch (e) {
      throw Exception('Error actualizando notas: ${e.message}');
    } catch (e) {
      throw Exception('Error actualizando notas: $e');
    }
  }

  Future<List<AlertasCumplimiento>> getComplianceAlerts({
    required String orgId,
    String? status,
    String? typeQuery,
    String? employeeQuery,
    String? branchId,
    GravedadAlerta? severity,
    int limit = 500,
  }) async {
    try {
      var query = supabase
          .from('alertas_cumplimiento')
          .select('''
            id, organizacion_id, empleado_id, tipo_alerta, detalle_tecnico, gravedad,
            estado, justificacion_auditor, creado_en,
            empleado:perfiles!alertas_cumplimiento_empleado_id_fkey(nombres, apellidos, cedula, sucursal_id)
          ''')
          .eq('organizacion_id', orgId);

      final s = status?.trim();
      if (s != null && s.isNotEmpty) {
        query = query.eq('estado', s);
      }

      final t = typeQuery?.trim();
      if (t != null && t.isNotEmpty) {
        query = query.ilike('tipo_alerta', '%$t%');
      }

      final q = employeeQuery?.trim();
      if (q != null && q.isNotEmpty) {
        query = query.or(
          'nombres.ilike.%$q%,apellidos.ilike.%$q%,cedula.ilike.%$q%',
          referencedTable: 'empleado',
        );
      }

      final b = branchId?.trim();
      if (b != null && b.isNotEmpty) {
        query = query.eq('empleado.sucursal_id', b);
      }

      if (severity != null) {
        query = query.eq('gravedad', severity.value);
      }

      final response = await query.order('creado_en', ascending: false).limit(limit);
      return (response as List)
          .map((e) => AlertasCumplimiento.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error consultando alertas: ${e.message}');
    } catch (e) {
      throw Exception('Error consultando alertas: $e');
    }
  }

  Future<int> countComplianceAlerts({
    required String orgId,
    List<String>? statuses,
  }) async {
    try {
      var query = supabase
          .from('alertas_cumplimiento')
          .select('id')
          .eq('organizacion_id', orgId);

      final s = statuses
          ?.map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (s != null && s.isNotEmpty) {
        query = query.inFilter('estado', s);
      }

      final response = await query.count();
      return response.count;
    } catch (e) {
      throw Exception('Error contando alertas: $e');
    }
  }

  Future<int> countPendingLeaveRequests({required String orgId}) async {
    try {
      final response = await supabase
          .from('solicitudes_permisos')
          .select('id')
          .eq('organizacion_id', orgId)
          .eq('estado', 'pendiente')
          .count();
      return response.count;
    } catch (e) {
      throw Exception('Error contando permisos: $e');
    }
  }

  Future<int> countAttendanceToday({required String orgId}) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final response = await supabase
          .from('registros_asistencia')
          .select('id')
          .eq('organizacion_id', orgId)
          .or('eliminado.is.null,eliminado.eq.false')
          .gte('fecha_hora_marcacion', start.toIso8601String())
          .lte('fecha_hora_marcacion', end.toIso8601String())
          .count();
      return response.count;
    } catch (e) {
      throw Exception('Error contando marcaciones: $e');
    }
  }

  Future<List<AuditoriaLog>> getAuditLog({
    required String orgId,
    DateTime? startDate,
    DateTime? endDate,
    String? actionQuery,
    String? table,
    String? actorId,
    String? branchId,
    int limit = 300,
  }) async {
    try {
      var query = supabase
          .from('auditoria_log')
          .select(
            'id, organizacion_id, actor_id, accion, tabla_afectada, registro_id, '
            'datos_anteriores, datos_nuevos, ip_address, user_agent, creado_en',
          )
          .eq('organizacion_id', orgId);

      final a = actorId?.trim();
      if (a != null && a.isNotEmpty) query = query.eq('actor_id', a);

      final t = table?.trim();
      if (t != null && t.isNotEmpty) query = query.eq('tabla_afectada', t);

      final aq = actionQuery?.trim();
      if (aq != null && aq.isNotEmpty) query = query.ilike('accion', '%$aq%');

      if (startDate != null) {
        query = query.gte('creado_en', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('creado_en', endDate.toIso8601String());
      }

      final response = await query.order('creado_en', ascending: false).limit(limit);
      final logs = (response as List)
          .map((e) => AuditoriaLog.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (logs.isEmpty) return const [];

      final actorIds = logs
          .map((l) => l.usuarioResponsableId)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final actorById = <String, Map<String, dynamic>>{};
      if (actorIds.isNotEmpty) {
        // Resolvemos nombres de actor desde `perfiles` (perfiles.id referencia auth.users).
        final profiles = await supabase
            .from('perfiles')
            .select('id, nombres, apellidos, cedula, rol, sucursal_id')
            .eq('organizacion_id', orgId)
            .inFilter('id', actorIds);
        for (final p in (profiles as List)) {
          final map = Map<String, dynamic>.from(p);
          final id = map['id']?.toString();
          if (id != null && id.isNotEmpty) actorById[id] = map;
        }
      }

      bool containsBranch(Map<String, dynamic>? m, String branchId) {
        if (m == null) return false;
        final candidates = [
          m['sucursal_id'],
          m['sucursalId'],
          m['branch_id'],
          m['branchId'],
        ];
        for (final v in candidates) {
          if (v != null && v.toString() == branchId) return true;
        }
        return false;
      }

      final b = branchId?.trim();
      final enriched = <AuditoriaLog>[];
      for (final log in logs) {
        final actor = log.usuarioResponsableId != null
            ? actorById[log.usuarioResponsableId!]
            : null;
        var next = log;
        if (actor != null) {
          next = next.copyWithActor(
            nombres: actor['nombres']?.toString(),
            apellidos: actor['apellidos']?.toString(),
            cedula: actor['cedula']?.toString(),
            rol: actor['rol']?.toString(),
            sucursalId: actor['sucursal_id']?.toString(),
          );
        }

        if (b != null && b.isNotEmpty) {
          final inActor = next.actorSucursalId == b;
          final inNew = containsBranch(next.datosNuevos, b);
          final inOld = containsBranch(next.datosAnteriores, b);
          if (!inActor && !inNew && !inOld) continue;
        }

        enriched.add(next);
      }

      return enriched;
    } on PostgrestException catch (e) {
      throw Exception('Error cargando auditoria: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando auditoria: $e');
    }
  }

  Future<List<Notificacion>> getMyNotifications({
    required String orgId,
    int limit = 100,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await supabase
          .from('notificaciones')
          .select()
          .eq('organizacion_id', orgId)
          .eq('usuario_destino_id', userId)
          .order('creado_en', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => Notificacion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error cargando notificaciones: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando notificaciones: $e');
    }
  }

  Future<int> getUnreadNotificationsCount({required String orgId}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await supabase
          .from('notificaciones')
          .select('id')
          .eq('organizacion_id', orgId)
          .eq('usuario_destino_id', userId)
          .eq('leido', false)
          .count();

      return response.count;
    } catch (_) {
      return 0;
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
    } on PostgrestException catch (e) {
      throw Exception('Error marcando notificacion: ${e.message}');
    } catch (e) {
      throw Exception('Error marcando notificacion: $e');
    }
  }

  Future<void> markAllMyNotificationsAsRead({required String orgId}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('organizacion_id', orgId)
          .eq('usuario_destino_id', userId)
          .eq('leido', false);
    } on PostgrestException catch (e) {
      throw Exception('Error marcando notificaciones: ${e.message}');
    } catch (e) {
      throw Exception('Error marcando notificaciones: $e');
    }
  }

  Future<String> uploadProfilePhoto(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    return StorageService.instance.uploadProfilePhoto(file, userId);
  }

  Future<void> updateMyProfile({String? fotoPerfilUrl}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final updates = <String, dynamic>{};
    if (fotoPerfilUrl != null) updates['foto_perfil_url'] = fotoPerfilUrl;
    if (updates.isEmpty) return;

    try {
      await supabase.from('perfiles').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error actualizando perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  // ==========================================================================
  // Permisos y Banco de horas (Auditoría)
  // ==========================================================================
  Future<List<dynamic>> getLeaveRequests({
    required String orgId,
    EstadoAprobacion? status,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeQuery,
    int limit = 300,
  }) async {
    try {
      // Retornamos dynamic o SolicitudesPermisos si tenemos el import
      // Como no tengo import visible de SolicitudesPermisos en este archivo, usare dynamic
      // y hare el cast afuera o añadire el import.
      // MEJOR: Añadir imports faltantes arriba en un paso separado si falla,
      // pero por ahora asumo que el servicio debe retornar List<SolicitudesPermisos>.
      // Voy a usar dynamic para evitar error de import inmediato y el provider lo mapea.
      // ESPERA, el prompt original tenia imports. Voy a revisar imports.
      // SÍ, falta importar SolicitudesPermisos y BancoHorasCompensatorias.
      // Lo hare en un paso previo o usare dynamic y map en provider?
      // Mejor retornar List<Map<String,dynamic>> o dynamic para ser seguro.
      var query = supabase
          .from('solicitudes_permisos')
          .select('''
            *,
            solicitante:perfiles!solicitudes_permisos_solicitante_id_fkey(
              id, nombres, apellidos, cedula, rol, sucursal_id
            )
          ''')
          .eq('organizacion_id', orgId);

      if (status != null) {
        query = query.eq('estado', status.value);
      }

      if (startDate != null) {
        query = query.gte('fecha_inicio', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('fecha_inicio', endDate.toIso8601String());
      }

      final q = employeeQuery?.trim();
      if (q != null && q.isNotEmpty) {
        query = query.or(
          'nombres.ilike.%$q%,apellidos.ilike.%$q%,cedula.ilike.%$q%',
          referencedTable: 'solicitante',
        );
      }

      final response = await query.order('creado_en', ascending: false).limit(limit);
      return response as List;
    } catch (e) {
      throw Exception('Error cargando permisos: $e');
    }
  }

  Future<List<dynamic>> getHoursBankEntries({
    required String orgId,
    String? employeeQuery,
    int limit = 300,
  }) async {
    try {
      var query = supabase
          .from('banco_horas')
          .select('''
            *,
            empleado:perfiles!banco_horas_empleado_id_fkey(
              id, nombres, apellidos, cedula, sucursal_id
            )
          ''')
          .eq('organizacion_id', orgId);

      final q = employeeQuery?.trim();
      if (q != null && q.isNotEmpty) {
         query = query.or(
          'nombres.ilike.%$q%,apellidos.ilike.%$q%,cedula.ilike.%$q%',
          referencedTable: 'empleado',
        );
      }

      final response = await query.order('creado_en', ascending: false).limit(limit);
      return response as List;
    } catch (e) {
      throw Exception('Error cargando banco de horas: $e');
    }
  }
}
