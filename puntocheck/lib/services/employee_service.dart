import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asignaciones_horarios.dart';
import '../models/employee_schedule.dart';
import '../models/enums.dart';
import '../models/perfiles.dart';
import '../models/banco_horas_compensatorias.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/organizaciones.dart';
import '../models/plantillas_horarios.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/sucursales.dart';
import 'storage_service.dart';
import 'supabase_client.dart';

/// Servicio dedicado al rol Employee.
///
/// Encapsula las lecturas y escrituras que ya están protegidas por RLS en la
/// base de datos.
class EmployeeService {
  EmployeeService._();
  static final instance = EmployeeService._();

  Future<Perfiles> getMyProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      final response = await supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('No se encontró perfil para el usuario actual');
      }

      return Perfiles.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error cargando perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado cargando perfil: $e');
    }
  }

  Future<String> _requireOrgId() async {
    final profile = await getMyProfile();
    final orgId = profile.organizacionId;
    if (orgId == null || orgId.isEmpty) {
      throw Exception('El usuario no tiene organización asignada');
    }
    return orgId;
  }

  Future<Map<String, dynamic>> getMyLegalConfig() async {
    final orgId = await _requireOrgId();
    try {
      final response = await supabase
          .from('organizaciones')
          .select('configuracion_legal')
          .eq('id', orgId)
          .maybeSingle();

      if (response == null) return {};
      return Map<String, dynamic>.from(response['configuracion_legal'] ?? {});
    } on PostgrestException catch (e) {
      throw Exception('Error cargando configuración legal: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando configuración legal: $e');
    }
  }

  Future<Organizaciones> getOrganizationById(String orgId) async {
    try {
      final response = await supabase
          .from('organizaciones')
          .select(
            'id, ruc, razon_social, plan_id, estado_suscripcion, fecha_fin_suscripcion, logo_url, eliminado, creado_en, actualizado_en',
          )
          .eq('id', orgId)
          .maybeSingle();

      if (response == null) throw Exception('No se encontró la organización');
      return Organizaciones.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Error cargando organización: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando organización: $e');
    }
  }

  Future<Organizaciones> getMyOrganization() async {
    final orgId = await _requireOrgId();
    return getOrganizationById(orgId);
  }

  Future<EmployeeSchedule?> getTodaySchedule() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T').first;

    try {
      final response = await supabase
          .from('asignaciones_horarios')
          .select(
            '''
              id, perfil_id, organizacion_id, plantilla_id, fecha_inicio, fecha_fin,
              plantillas_horarios (
                id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos,
                es_rotativo, eliminado, creado_en,
                turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
              )
            ''',
          )
          .eq('perfil_id', userId)
          .eq('organizacion_id', orgId)
          .lte('fecha_inicio', todayStr)
          .or('fecha_fin.is.null,fecha_fin.gte.$todayStr')
          .order('fecha_inicio', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      if (response['plantillas_horarios'] == null) return null;

      return EmployeeSchedule(
        asignacion: AsignacionesHorarios.fromJson(response),
        plantilla: PlantillasHorarios.fromJson(response['plantillas_horarios']),
      );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando turno de hoy: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando turno de hoy: $e');
    }
  }

  Future<EmployeeSchedule?> getNextSchedule({DateTime? from}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    final base = (from ?? DateTime.now());
    final baseStr = base.toIso8601String().split('T').first;

    try {
      final response = await supabase
          .from('asignaciones_horarios')
          .select(
            '''
              id, perfil_id, organizacion_id, plantilla_id, fecha_inicio, fecha_fin,
              plantillas_horarios (
                id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos,
                es_rotativo, eliminado, creado_en,
                turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
              )
            ''',
          )
          .eq('perfil_id', userId)
          .eq('organizacion_id', orgId)
          .gt('fecha_inicio', baseStr)
          .order('fecha_inicio', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      if (response['plantillas_horarios'] == null) return null;

      return EmployeeSchedule(
        asignacion: AsignacionesHorarios.fromJson(response),
        plantilla: PlantillasHorarios.fromJson(response['plantillas_horarios']),
      );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando próximo horario: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando próximo horario: $e');
    }
  }

  Future<RegistrosAsistencia?> getLastAttendanceRecord() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      final response = await supabase
          .from('registros_asistencia')
          .select()
          .eq('perfil_id', userId)
          .eq('eliminado', false)
          .order('fecha_hora_marcacion', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RegistrosAsistencia.fromDynamic(response);
    } on PostgrestException catch (e) {
      throw Exception('Error consultando última marcación: ${e.message}');
    } catch (e) {
      throw Exception('Error consultando última marcación: $e');
    }
  }

  Future<List<RegistrosAsistencia>> getAttendanceHistory({
    int limit = 200,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      var query = supabase
          .from('registros_asistencia')
          .select('*, sucursales(nombre), turnos_jornada(nombre_turno,hora_inicio,hora_fin)')
          .eq('perfil_id', userId)
          .eq('organizacion_id', orgId)
          .eq('eliminado', false);

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
          .map((json) => RegistrosAsistencia.fromDynamic(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo historial: ${e.message}');
    } catch (e) {
      throw Exception('Error obteniendo historial: $e');
    }
  }

  Future<List<SolicitudesPermisos>> getMyPermissions() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      final response = await supabase
          .from('solicitudes_permisos')
          .select()
          .eq('solicitante_id', userId)
          .eq('organizacion_id', orgId)
          .order('creado_en', ascending: false);

      return (response as List)
          .map((json) => SolicitudesPermisos.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo permisos: ${e.message}');
    } catch (e) {
      throw Exception('Error obteniendo permisos: $e');
    }
  }

  Future<List<BancoHorasCompensatorias>> getMyHoursBank({int limit = 200}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      final response = await supabase
          .from('banco_horas')
          .select()
          .eq('empleado_id', userId)
          .eq('organizacion_id', orgId)
          .order('creado_en', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => BancoHorasCompensatorias.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo banco de horas: ${e.message}');
    } catch (e) {
      throw Exception('Error obteniendo banco de horas: $e');
    }
  }

  Future<List<AlertasCumplimiento>> getMyComplianceAlerts({int limit = 100}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      final response = await supabase
          .from('alertas_cumplimiento')
          .select()
          .eq('organizacion_id', orgId)
          .eq('empleado_id', userId)
          .order('creado_en', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AlertasCumplimiento.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo alertas de cumplimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error obteniendo alertas de cumplimiento: $e');
    }
  }

  Future<List<Sucursales>> getMyBranches() async {
    final profile = await getMyProfile();
    final sucursalId = profile.sucursalId;
    if (sucursalId == null || sucursalId.isEmpty) {
      throw Exception('Tu usuario no tiene sucursal asignada.');
    }

    try {
      final response = await supabase
          .from('sucursales')
          .select()
          .eq('id', sucursalId)
          .or('eliminado.is.null,eliminado.eq.false')
          .limit(1);

      return (response as List)
          .map((json) => Sucursales.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo sucursales: ${e.message}');
    } catch (e) {
      throw Exception('Error obteniendo sucursales: $e');
    }
  }

  Future<Map<String, String>> validateQr(String scannedData) async {
    final profile = await getMyProfile();
    final myOrgId = profile.organizacionId;
    final mySucursalId = profile.sucursalId;

    final parsed = _parseQrPayload(scannedData);
    final token = parsed['token'];
    final sucursalHint = parsed['sucursal_id'];

    if (token == null || token.isEmpty) {
      throw Exception('QR inválido o vacío');
    }

    final hash = sha256.convert(utf8.encode(token)).toString();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      var query = supabase
          .from('qr_codigos')
          .select('id, sucursal_id, organizacion_id, fecha_expiracion, es_valido')
          .eq('token_hash', hash)
          .eq('es_valido', true)
          .gt('fecha_expiracion', now);

      if (sucursalHint != null && sucursalHint.isNotEmpty) {
        query = query.eq('sucursal_id', sucursalHint);
      }

      final response = await query.maybeSingle();
      if (response == null) {
        throw Exception('QR inválido o expirado');
      }

      final qrOrgId = response['organizacion_id'] as String?;
      final qrSucursalId = response['sucursal_id'] as String?;

      if (myOrgId != null &&
          myOrgId.isNotEmpty &&
          qrOrgId != null &&
          qrOrgId.isNotEmpty &&
          qrOrgId != myOrgId) {
        throw Exception('Este QR no pertenece a tu organizacion.');
      }

      if (mySucursalId != null &&
          mySucursalId.isNotEmpty &&
          qrSucursalId != null &&
          qrSucursalId.isNotEmpty &&
          qrSucursalId != mySucursalId) {
        throw Exception('Este QR no pertenece a tu sucursal.');
      }

      return {
        'sucursal_id': response['sucursal_id'] as String,
        'organizacion_id': response['organizacion_id'] as String,
      };
    } on PostgrestException catch (e) {
      throw Exception('Error validando QR: ${e.message}');
    } catch (e) {
      throw Exception('Error validando QR: $e');
    }
  }

  Future<String> uploadEvidence(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    return StorageService.instance.uploadEvidence(file, userId);
  }

  Future<String> uploadDocument(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    return StorageService.instance.uploadLegalDoc(file, userId);
  }

  Future<String> uploadProfilePhoto(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    return StorageService.instance.uploadProfilePhoto(file, userId);
  }

  Future<void> createPermissionRequest({
    required TipoPermiso tipo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivoDetalle,
    String? documentoUrl,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    final start = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final end = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    if (end.isBefore(start)) {
      throw Exception('La fecha fin no puede ser anterior a la fecha inicio.');
    }
    final diasTotales = end.difference(start).inDays + 1;

    try {
      await supabase.from('solicitudes_permisos').insert({
        'organizacion_id': orgId,
        'solicitante_id': userId,
        'tipo': tipo.value,
        'fecha_inicio': start.toIso8601String().split('T').first,
        'fecha_fin': end.toIso8601String().split('T').first,
        'dias_totales': diasTotales,
        'motivo_detalle': motivoDetalle,
        'documento_url': documentoUrl,
        'estado': EstadoAprobacion.pendiente.value,
      });
    } on PostgrestException catch (e) {
      throw Exception('Error creando solicitud: ${e.message}');
    } catch (e) {
      throw Exception('Error creando solicitud: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      final response = await supabase
          .from('notificaciones')
          .select()
          .eq('usuario_destino_id', userId)
          .eq('organizacion_id', orgId)
          .order('creado_en', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error cargando notificaciones: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      await supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('id', notificationId)
          .eq('usuario_destino_id', userId);
    } catch (e) {
      throw Exception('Error marcando notificación: $e');
    }
  }

  Future<void> markAllMyNotificationsAsRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    try {
      await supabase
          .from('notificaciones')
          .update({'leido': true})
          .eq('usuario_destino_id', userId)
          .eq('organizacion_id', orgId)
          .eq('leido', false);
    } catch (e) {
      throw Exception('Error marcando notificaciones: $e');
    }
  }

  Future<void> updateProfile({String? telefono, String? fotoPerfilUrl}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final updates = <String, dynamic>{};
    if (telefono != null) updates['telefono'] = telefono;
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

  Future<void> registerAttendanceFull({
    required String tipoRegistro,
    required String evidenciaFotoUrl,
    double? latitud,
    double? longitud,
    String? sucursalId,
    String? turnoJornadaId,
    required bool estaDentroGeocerca,
    String? notas,
    required bool isQr,
    double? precisionMetros,
    bool esMockLocation = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    final orgId = await _requireOrgId();

    final payload = <String, dynamic>{
      'perfil_id': userId,
      'organizacion_id': orgId,
      'sucursal_id': sucursalId,
      'tipo_registro': tipoRegistro,
      'fecha_hora_marcacion': DateTime.now().toUtc().toIso8601String(),
      'precision_metros': precisionMetros,
      'esta_dentro_geocerca': estaDentroGeocerca,
      'es_mock_location': esMockLocation,
      'evidencia_foto_url': evidenciaFotoUrl,
      'origen': isQr ? OrigenMarcacion.qrFijo.value : OrigenMarcacion.gpsMovil.value,
      'notas': notas,
      'turno_jornada_id': turnoJornadaId,
      'eliminado': false,
    };

    // PostGIS geography/geometry en PostgREST suele aceptar mejor WKT/EWKT que GeoJSON.
    if (latitud != null && longitud != null) {
      payload['ubicacion_gps'] = 'SRID=4326;POINT($longitud $latitud)';
    }

    try {
      await supabase.from('registros_asistencia').insert(payload);
    } on PostgrestException catch (e) {
      throw Exception('Error registrando asistencia: ${e.message}');
    } catch (e) {
      throw Exception('Error registrando asistencia: $e');
    }
  }

  Map<String, String?> _parseQrPayload(String raw) {
    final cleaned = raw.trim();

    // Intentar JSON: {"token": "...", "sucursal_id": "..."}
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['token'] as String?;
        final sucursalId = decoded['sucursal_id'] as String?;
        if (token != null) {
          return {'token': token, 'sucursal_id': sucursalId};
        }
      }
    } catch (_) {
      // No es JSON, continuamos con los demás formatos.
    }

    // Intentar formato token|sucursalId
    if (cleaned.contains('|')) {
      final parts = cleaned.split('|');
      if (parts.length >= 2) {
        return {'token': parts[0], 'sucursal_id': parts[1]};
      }
    }

    // Fallback: solo token
    return {'token': cleaned, 'sucursal_id': null};
  }
}
