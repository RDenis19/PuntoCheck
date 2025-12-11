import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/perfiles.dart';
import '../models/registros_asistencia.dart';
import '../models/solicitudes_permisos.dart';
import '../models/sucursales.dart';
import '../models/enums.dart';
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

/// Turno vigente para hoy (asignación + plantilla).
final employeeScheduleProvider = FutureProvider<EmployeeSchedule?>((ref) async {
  return ref.read(employeeServiceProvider).getTodaySchedule();
});

/// Última marcación registrada del día.
final lastAttendanceProvider = FutureProvider<RegistrosAsistencia?>((ref) async {
  return ref.read(employeeServiceProvider).getLastAttendanceRecord();
});

/// Historial de asistencia del employee.
final employeeAttendanceHistoryProvider = FutureProvider<List<RegistrosAsistencia>>((ref) async {
  return ref.read(employeeServiceProvider).getAttendanceHistory(limit: 50);
});

/// Solicitudes de permisos del employee.
final employeePermissionsProvider = FutureProvider<List<SolicitudesPermisos>>((ref) async {
  return ref.read(employeeServiceProvider).getMyPermissions();
});

/// Sucursales disponibles para validar geocerca / QR.
final employeeBranchesProvider = FutureProvider<List<Sucursales>>((ref) async {
  return ref.read(employeeServiceProvider).getMyBranches();
});

/// Crear solicitud de permiso.
class EmployeePermissionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> create({
    required TipoPermiso tipo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int diasTotales,
    String? motivoDetalle,
    String? documentoUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(employeeServiceProvider).createPermissionRequest(
          tipo: tipo,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          diasTotales: diasTotales,
          motivoDetalle: motivoDetalle,
          documentoUrl: documentoUrl,
        ));
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
}

final employeeNotificationControllerProvider =
    AsyncNotifierProvider<EmployeeNotificationController, void>(
  EmployeeNotificationController.new,
);

/// Controlador para acciones de marcación (usa servicios, no UI).
class EmployeeAttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<Map<String, String>> validateQr(String data) {
    return ref.read(employeeServiceProvider).validateQr(data);
  }

  Future<void> registerAttendance({
    required String tipoRegistro,
    required bool isQr,
    required double latitud,
    required double longitud,
    String? sucursalId,
    required bool estaDentroGeocerca,
    File? evidenciaPhoto,
    String? notas,
    required String deviceId,
    required String deviceModel,
    double? precisionMetros,
    bool esMockLocation = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final svc = ref.read(employeeServiceProvider);
      final photoUrl = evidenciaPhoto != null
          ? await svc.uploadEvidence(evidenciaPhoto)
          : 'qr_verified_no_photo';

      await svc.registerAttendanceFull(
        tipoRegistro: tipoRegistro,
        evidenciaFotoUrl: photoUrl,
        latitud: latitud,
        longitud: longitud,
        sucursalId: sucursalId,
        estaDentroGeocerca: estaDentroGeocerca,
        notas: notas,
        deviceId: deviceId,
        deviceModel: deviceModel,
        isQr: isQr,
        precisionMetros: precisionMetros,
        esMockLocation: esMockLocation,
      );
    });

    if (!state.hasError) {
      ref
        ..invalidate(employeeAttendanceHistoryProvider)
        ..invalidate(lastAttendanceProvider);
    }
  }
}

final employeeAttendanceControllerProvider =
    AsyncNotifierProvider<EmployeeAttendanceController, void>(
  EmployeeAttendanceController.new,
);
