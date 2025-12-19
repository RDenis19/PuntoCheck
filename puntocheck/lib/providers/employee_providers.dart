import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/sucursales.dart';
import '../models/enums.dart';
import '../models/banco_horas_compensatorias.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/employee_schedule.dart';
import '../models/organizaciones.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import 'auth_providers.dart';

/// Servicio del rol employee.
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService.instance;
});

/// Perfil del employee (reusa el provider global, pero garantiza no-null).
final employeeProfileProvider = FutureProvider<Perfiles>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) throw Exception('No se pudo cargar el perfil');
  return profile;
});

/// Organización del employee (para mostrar nombre/branding).
final employeeOrganizationProvider = FutureProvider<Organizaciones>((ref) async {
  final profile = await ref.watch(employeeProfileProvider.future);
  final orgId = profile.organizacionId;
  if (orgId == null || orgId.isEmpty) {
    throw Exception('No tienes organización asignada');
  }
  return ref.read(employeeServiceProvider).getOrganizationById(orgId);
});

/// Turno vigente para hoy (asignación + plantilla).
final employeeScheduleProvider = FutureProvider<EmployeeSchedule?>((ref) async {
  return ref.read(employeeServiceProvider).getTodaySchedule();
});

/// Próximo horario (cuando no hay turno hoy o para previsualizar la próxima asignación).
final employeeNextScheduleProvider = FutureProvider<EmployeeSchedule?>((ref) async {
  return ref.read(employeeServiceProvider).getNextSchedule();
});

/// Última marcación registrada del día.
final lastAttendanceProvider = FutureProvider<RegistrosAsistencia?>((ref) async {
  return ref.read(employeeServiceProvider).getLastAttendanceRecord();
});

/// Historial de asistencia del employee.
final employeeAttendanceHistoryProvider = FutureProvider<List<RegistrosAsistencia>>((ref) async {
  return ref.read(employeeServiceProvider).getAttendanceHistory(limit: 500);
});

/// Banco de horas del employee (solo lectura).
final employeeHoursBankProvider =
    FutureProvider<List<BancoHorasCompensatorias>>((ref) async {
  return ref.read(employeeServiceProvider).getMyHoursBank(limit: 200);
});

/// Alertas de cumplimiento (visión personal, solo lectura).
final employeeComplianceAlertsProvider =
    FutureProvider<List<AlertasCumplimiento>>((ref) async {
  return ref.read(employeeServiceProvider).getMyComplianceAlerts(limit: 200);
});

/// Solicitudes de permisos del employee.
final employeePermissionsProvider = FutureProvider<List<SolicitudesPermisos>>((ref) async {
  return ref.read(employeeServiceProvider).getMyPermissions();
});

/// Sucursales disponibles para validar geocerca / QR.
final employeeBranchesProvider = FutureProvider<List<Sucursales>>((ref) async {
  return ref.read(employeeServiceProvider).getMyBranches();
});

/// Realtime listener (Supabase Realtime) para mantener Inicio actualizado.
///
/// Requiere que `registros_asistencia` y `notificaciones` tengan Realtime habilitado en Supabase
/// (Database > Replication) y que RLS permita los eventos para el usuario autenticado.
final employeeRealtimeListenerProvider = Provider.autoDispose<void>((ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;

  void invalidateAttendance() {
    ref
      ..invalidate(lastAttendanceProvider)
      ..invalidate(employeeAttendanceHistoryProvider);
  }

  void invalidateNotifications() {
    ref.invalidate(employeeNotificationsProvider);
  }

  void invalidateSchedule() {
    ref
      ..invalidate(employeeScheduleProvider)
      ..invalidate(employeeNextScheduleProvider);
  }

  void invalidateHoursBank() {
    ref.invalidate(employeeHoursBankProvider);
  }

  void invalidateComplianceAlerts() {
    ref.invalidate(employeeComplianceAlertsProvider);
  }

  final channel = client.channel('rt_employee_$userId')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'registros_asistencia',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'perfil_id',
        value: userId,
      ),
      callback: (_) => invalidateAttendance(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'asignaciones_horarios',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'perfil_id',
        value: userId,
      ),
      callback: (_) => invalidateSchedule(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'banco_horas',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'empleado_id',
        value: userId,
      ),
      callback: (_) => invalidateHoursBank(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notificaciones',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'usuario_destino_id',
        value: userId,
      ),
      callback: (_) => invalidateNotifications(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'alertas_cumplimiento',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'empleado_id',
        value: userId,
      ),
      callback: (_) => invalidateComplianceAlerts(),
    )
    ..subscribe();

  ref.onDispose(() => client.removeChannel(channel));
});

/// Configuración legal de la organización (descanso/tolerancia).
///
/// Nota: requiere que `public.organizaciones` permita SELECT (RLS/GRANT) al rol `authenticated`.
final employeeLegalConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(employeeServiceProvider).getMyLegalConfig();
  } catch (_) {
    return {};
  }
});

/// Crear solicitud de permiso.
class EmployeePermissionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createRequest({
    required TipoPermiso tipo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? motivoDetalle,
    File? documento,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final svc = ref.read(employeeServiceProvider);
      String? docUrl;
      if (documento != null) {
        docUrl = await svc.uploadDocument(documento);
      }
      await svc.createPermissionRequest(
        tipo: tipo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivoDetalle: motivoDetalle,
        documentoUrl: docUrl,
      );
    });
    if (!state.hasError) {
      ref.invalidate(employeePermissionsProvider);
    }
  }
}

final employeePermissionControllerProvider =
    AsyncNotifierProvider<EmployeePermissionController, void>(
  EmployeePermissionController.new,
);

/// Notificaciones del empleado.
final employeeNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(employeeServiceProvider).getMyNotifications();
});

class EmployeeNotificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> markRead(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(employeeServiceProvider).markNotificationAsRead(notificationId),
    );
    if (!state.hasError) ref.invalidate(employeeNotificationsProvider);
  }

  Future<void> markAllRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(employeeServiceProvider).markAllMyNotificationsAsRead(),
    );
    if (!state.hasError) ref.invalidate(employeeNotificationsProvider);
  }
}

final employeeNotificationControllerProvider =
    AsyncNotifierProvider<EmployeeNotificationController, void>(
  EmployeeNotificationController.new,
);

/// Controlador para acciones de marcación (usa servicios, no UI).
class EmployeeAttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  static const _allowedEmployeeTypes = <String>{
    'entrada',
    'salida',
    'inicio_break',
    'fin_break',
  };

  Future<Map<String, String>> validateQr(String data) {
    return ref.read(employeeServiceProvider).validateQr(data);
  }

  Future<Map<String, dynamic>?> registerAttendance({
    required String tipoRegistro,
    required bool isQr,
    double? latitud,
    double? longitud,
    String? sucursalId,
    required bool estaDentroGeocerca,
    File? evidenciaPhoto,
    String? notas,
    double? precisionMetros,
    bool esMockLocation = false,
  }) async {
    state = const AsyncValue.loading();
    Map<String, dynamic>? result;
    state = await AsyncValue.guard(() async {
      final svc = ref.read(employeeServiceProvider);

      if (!_allowedEmployeeTypes.contains(tipoRegistro)) {
        throw Exception('Tipo de registro no permitido: $tipoRegistro');
      }

      final effectiveSucursalId = (sucursalId != null && sucursalId.isNotEmpty)
          ? sucursalId
          : (await svc.getMyProfile()).sucursalId;
      if (effectiveSucursalId == null || effectiveSucursalId.isEmpty) {
        throw Exception(
          'No se pudo determinar tu sucursal. Pide a tu administrador que te asigne una sucursal.',
        );
      }

      if (!isQr && (latitud == null || longitud == null)) {
        throw Exception('No se pudo obtener tu ubicación. Activa GPS y reintenta.');
      }

      if (evidenciaPhoto == null) {
        throw Exception('Debes tomar una foto para registrar la asistencia.');
      }

      final evidenceUrl = await svc.uploadEvidence(evidenciaPhoto).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
          'Tiempo de espera agotado subiendo la foto. Revisa tu internet y reintenta.',
        ),
      );

      try {
        if (isQr) {
          // Marcación por QR: no depende de GPS, y debe registrar origen QR.
          await svc
              .registerAttendanceFull(
                tipoRegistro: tipoRegistro,
                evidenciaFotoUrl: evidenceUrl,
                latitud: null,
                longitud: null,
                sucursalId: effectiveSucursalId,
                estaDentroGeocerca: true,
                notas: notas ?? 'Validado por QR',
                isQr: true,
                precisionMetros: null,
                esMockLocation: esMockLocation,
              )
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () => throw Exception(
                  'El servidor no respondió a tiempo registrando la asistencia. Reintenta.',
                ),
              );
          result = {'success': true, 'evidencia_foto_url': evidenceUrl};
        } else if (latitud != null && longitud != null) {
          final rpcResult = await AttendanceService.instance
              .performCheckIn(
                lat: latitud,
                long: longitud,
                photoPath: evidenceUrl,
                type: tipoRegistro,
                sucursalId: effectiveSucursalId,
              )
              .timeout(
                const Duration(seconds: 25),
                onTimeout: () => throw Exception(
                  'El servidor no respondió a tiempo registrando la asistencia. Reintenta.',
                ),
              );
          result = Map<String, dynamic>.from(rpcResult)
            ..['evidencia_foto_url'] = evidenceUrl;
        } else {
          // Sin GPS (p.ej. entornos limitados): insert directo.
          await svc
              .registerAttendanceFull(
                tipoRegistro: tipoRegistro,
                evidenciaFotoUrl: evidenceUrl,
                latitud: null,
                longitud: null,
                sucursalId: effectiveSucursalId,
                estaDentroGeocerca: estaDentroGeocerca,
                notas: notas,
                isQr: isQr,
                precisionMetros: null,
                esMockLocation: esMockLocation,
              )
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () => throw Exception(
                  'El servidor no respondió a tiempo registrando la asistencia. Reintenta.',
                ),
              );
          result = {'success': true, 'evidencia_foto_url': evidenceUrl};
        }
      } catch (e) {
        // Fallback si el RPC no existe en el backend (entornos antiguos).
        final msg = e.toString();
        final isMissingRpc = msg.contains('PGRST202') ||
            msg.contains('Could not find the function') ||
            msg.contains('realizar_checkin');

        // Algunos entornos tienen el RPC pero fallan por incompatibilidades (p.ej. geometría).
        // En ese caso hacemos insert directo para no bloquear la marcación.
        final isRpcGeometryIssue = msg.contains('invalid geometry') || msg.contains('parse error');

        if (!isMissingRpc && !isRpcGeometryIssue) rethrow;

        await svc
            .registerAttendanceFull(
              tipoRegistro: tipoRegistro,
              evidenciaFotoUrl: evidenceUrl,
              latitud: latitud,
              longitud: longitud,
              sucursalId: effectiveSucursalId,
              estaDentroGeocerca: estaDentroGeocerca,
              notas: notas,
              isQr: isQr,
              precisionMetros: precisionMetros,
              esMockLocation: esMockLocation,
            )
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw Exception(
                'El servidor no respondió a tiempo registrando la asistencia. Reintenta.',
              ),
            );
        result = null;
      }
    });

    if (!state.hasError) {
      ref
        ..invalidate(employeeAttendanceHistoryProvider)
        ..invalidate(lastAttendanceProvider);
    }

    return result;
  }
}

final employeeAttendanceControllerProvider =
    AsyncNotifierProvider<EmployeeAttendanceController, void>(
  EmployeeAttendanceController.new,
);
