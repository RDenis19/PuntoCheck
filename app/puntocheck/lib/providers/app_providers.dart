import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User, AuthState;

// Modelos
import '../models/profile_model.dart';
import '../models/enums.dart';
import '../models/organization_model.dart';
import '../models/work_shift_model.dart';
import '../models/work_schedule_model.dart';
import '../models/notification_model.dart';
import '../models/geo_location.dart';
import '../utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';

// Servicios
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/organization_service.dart';
import '../services/super_admin_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../services/biometric_service.dart';
import '../services/global_settings_service.dart';

// ============================================================================
// 1. CAPA DE SERVICIOS (INYECCIÓN DE DEPENDENCIAS)
// ============================================================================
/// Proveedor de AuthService - Inyección de dependencia
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Proveedor de AttendanceService - Inyección de dependencia
final attendanceServiceProvider = Provider<AttendanceService>(
  (ref) => AttendanceService(),
);

/// Proveedor de OrganizationService (admin + super admin centralizado)
final organizationServiceProvider = Provider<OrganizationService>(
  (ref) => OrganizationService(),
);

/// Alias legacy para mantener compatibilidad con imports antiguos.
final superAdminServiceProvider = Provider<SuperAdminService>(
  (ref) => ref.read(organizationServiceProvider),
);

/// Proveedor de StorageService - Inyección de dependencia
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

/// Proveedor de NotificationService - Inyección de dependencia
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class AnnouncementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createAnnouncement({
    required String title,
    required String body,
    NotifType type = NotifType.info,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizationId;
      if (orgId == null) {
        throw Exception('No se encontro organizacion para el admin.');
      }
      await ref.read(notificationServiceProvider).createAnnouncement(
            organizationId: orgId,
            title: title,
            body: body,
            type: type,
          );
      ref.invalidate(notificationsStreamProvider);
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    NotifType type = NotifType.info,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizationId;
      if (orgId == null) {
        throw Exception('No se encontro organizacion para el admin.');
      }
      await ref.read(notificationServiceProvider).updateAnnouncement(
            id: id,
            organizationId: orgId,
            title: title,
            body: body,
            type: type,
          );
      ref.invalidate(notificationsStreamProvider);
    });
  }

  Future<void> deleteAnnouncement({required String id}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizationId;
      if (orgId == null) {
        throw Exception('No se encontro organizacion para el admin.');
      }
      await ref
          .read(notificationServiceProvider)
          .deleteAnnouncement(id: id, organizationId: orgId);
      ref.invalidate(notificationsStreamProvider);
    });
  }
}

final announcementControllerProvider =
    AsyncNotifierProvider<AnnouncementController, void>(
  AnnouncementController.new,
);

/// Proveedor de ScheduleService - Inyección de dependencia
final scheduleServiceProvider = Provider<ScheduleService>(
  (ref) => ScheduleService(),
);

/// Proveedor de BiometricService - Inyección de dependencia
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// Proveedor de configuracion global
final globalSettingsServiceProvider = Provider<GlobalSettingsService>(
  (ref) => GlobalSettingsService(),
);

// ============================================================================
// 2. AUTENTICACIÓN (AUTH STATE & CURRENT USER)
// ============================================================================
/// Stream del estado de autenticación de Supabase
/// Emite cambios cuando el usuario inicia/cierra sesión
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Usuario actual desde Supabase Auth
/// null si no está autenticado
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

/// Controller de autenticación - Maneja SignIn, SignUp, SignOut, ResetPassword
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Inicia sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(email, password),
    );
  }

  /// Registra un nuevo usuario
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? organizationId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authServiceProvider)
          .signUp(
            email: email,
            password: password,
            fullName: fullName,
            organizationId: organizationId,
          ),
    );
  }

  /// Cierra sesión
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
  }

  /// Inicia recuperación de contraseña
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).resetPassword(email),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

// ============================================================================
// 3. PERFIL DE USUARIO (PROFILE MANAGEMENT)
// ============================================================================
/// Controller de perfil - Carga, actualiza y maneja el perfil del usuario
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    try {
      return await ref.read(authServiceProvider).getCurrentUserProfile();
    } catch (e) {
      // Retornar null si falla la carga del perfil
      return null;
    }
  }

  /// Refresca el perfil desde la base de datos
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Actualiza los datos del perfil
  Future<void> updateProfile(Profile updatedProfile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).updateProfile(updatedProfile);
      return updatedProfile;
    });
  }

  /// Sube un avatar y actualiza el perfil
  Future<void> uploadAvatar(File imageFile) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final url = await service.uploadAvatar(imageFile, currentProfile.id);
      final newProfile = currentProfile.copyWith(avatarUrl: url);
      await authService.updateProfile(newProfile);
      return newProfile;
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileController, Profile?>(
  ProfileController.new,
);

// ============================================================================
// 3.B ROL DE USUARIO (DERIVADO DEL PERFIL)
// ============================================================================
/// Rol del usuario para controlar rutas y permisos
enum UserRole { superAdmin, admin, employee, unknown }

final userRoleProvider = Provider.autoDispose<UserRole>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final currentUser = ref.watch(currentUserProvider);
  final metaIsSuperAdmin =
      ((currentUser?.userMetadata ?? const {})['is_super_admin'] as bool?) ==
          true;
  final metaIsOrgAdmin =
      ((currentUser?.userMetadata ?? const {})['is_org_admin'] as bool?) ==
          true;

  return profileAsync.when(
    data: (profile) {
      final isSuper = (profile?.isSuperAdmin == true) || metaIsSuperAdmin;
      final isAdmin = (profile?.isOrgAdmin == true) || metaIsOrgAdmin;

      if (isSuper) return UserRole.superAdmin;
      if (isAdmin) return UserRole.admin;
      if (profile != null) return UserRole.employee;

      if (metaIsSuperAdmin) return UserRole.superAdmin;
      if (metaIsOrgAdmin) return UserRole.admin;
      return UserRole.unknown;
    },
    loading: () => UserRole.unknown,
    error: (_, __) => UserRole.unknown,
  );
});

// ============================================================================
// 4. ORGANIZACIÓN (ORGANIZATION MANAGEMENT)
// ============================================================================
/// Obtiene la organización actual del usuario autenticado
final currentOrganizationProvider = FutureProvider.autoDispose<Organization?>((
  ref,
) async {
  ref.watch(authStateProvider);
  return ref.watch(organizationServiceProvider).getMyOrganization();
});

/// Obtiene todas las organizaciones (Solo SUPERADMIN)
final allOrganizationsProvider = FutureProvider.autoDispose<List<Organization>>(
  (ref) async {
    final result = await ref.watch(organizationServiceProvider).getOrganizationsPage(
          page: 1,
          pageSize: 15,
          sortBy: 'created_at',
          ascending: false,
        );
    return result.items;
  },
);

/// Parametros tipados para la paginacion de organizaciones.
class OrganizationPageRequest {
  const OrganizationPageRequest({
    this.page = 1,
    this.pageSize = 12,
    this.search,
    this.status,
    this.sortBy = 'created_at',
    this.ascending = false,
  });

  final int page;
  final int pageSize;
  final String? search;
  final OrgStatus? status;
  final String sortBy;
  final bool ascending;

  @override
  bool operator ==(Object other) {
    return other is OrganizationPageRequest &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.search == search &&
        other.status == status &&
        other.sortBy == sortBy &&
        other.ascending == ascending;
  }

  @override
  int get hashCode =>
      Object.hash(page, pageSize, search, status, sortBy, ascending);
}

/// Request por defecto usado en home de superadmin (organizaciones recientes).
const defaultOrganizationsPageRequest = OrganizationPageRequest(
  page: 1,
  pageSize: 6,
  sortBy: 'created_at',
  ascending: false,
);

/// Paginacion server side de organizaciones (Super Admin).
final organizationsPageProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Organization>, OrganizationPageRequest>((
  ref,
  params,
) async {
  return ref.watch(organizationServiceProvider).getOrganizationsPage(
        page: params.page,
        pageSize: params.pageSize,
        search: params.search,
        status: params.status,
        sortBy: params.sortBy,
        ascending: params.ascending,
      );
});

/// Cantidad de organizaciones por estado (se actualiza con la busqueda).
final organizationStatusCountsProvider =
    FutureProvider.autoDispose.family<Map<OrgStatus, int>, String?>((
  ref,
  search,
) async {
  return ref
      .watch(organizationServiceProvider)
      .getOrganizationStatusCounts(search: search);
});

/// Estadisticas para el dashboard de administrador (Admin)
final adminDashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final profile = await ref.watch(profileProvider.future);
      final orgId = profile?.organizationId;

      if (orgId == null) {
        throw Exception('El usuario no tiene organizacion asignada.');
      }

      return ref
          .watch(organizationServiceProvider)
          .getAdminDashboardStats(orgId);
    });

/// Empleados de una organizacion (SuperAdmin/Admin)
final organizationEmployeesProvider = FutureProvider.autoDispose
    .family<List<Profile>, String>((ref, orgId) async {
      return ref.watch(organizationServiceProvider).getEmployeesByOrg(orgId);
    });

/// Parametros tipados para paginacion de empleados por organizacion.
class EmployeePageRequest {
  const EmployeePageRequest({
    required this.organizationId,
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.onlyAdmins,
    this.excludeAdmins,
  });

  final String organizationId;
  final int page;
  final int pageSize;
  final String? search;
  final bool? onlyAdmins;
  final bool? excludeAdmins;

  @override
  bool operator ==(Object other) {
    return other is EmployeePageRequest &&
        other.organizationId == organizationId &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.search == search &&
        other.onlyAdmins == onlyAdmins &&
        other.excludeAdmins == excludeAdmins;
  }

  @override
  int get hashCode => Object.hash(
        organizationId,
        page,
        pageSize,
        search,
        onlyAdmins,
        excludeAdmins,
      );
}

/// Paginacion server side de empleados por organizacion (Super Admin/Admin).
final organizationEmployeesPageProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Profile>, EmployeePageRequest>((
  ref,
  params,
) async {
  return ref.watch(organizationServiceProvider).getEmployeesPage(
        organizationId: params.organizationId,
        page: params.page,
        pageSize: params.pageSize,
        search: params.search,
        onlyAdmins: params.onlyAdmins,
        excludeAdmins: params.excludeAdmins,
      );
});

/// Empleados de la organizacion del usuario (Admin)
final orgEmployeesProvider = FutureProvider.autoDispose<List<Profile>>((
  ref,
) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizationId;
  if (orgId == null) return <Profile>[];
  return ref.watch(organizationServiceProvider).getEmployeesByOrg(orgId);
});

/// Contenedor tipado para estadisticas de una organizacion (SuperAdmin/Admin)
class OrganizationDashboardSnapshot {
  const OrganizationDashboardSnapshot({
    required this.totalEmployees,
    required this.activeToday,
    required this.attendanceAverage,
  });

  final int totalEmployees;
  final int activeToday;
  final int attendanceAverage;
}

/// Estadisticas por organizacion reutilizables en UI
final organizationDashboardStatsProvider = FutureProvider.autoDispose
    .family<OrganizationDashboardSnapshot, String>((ref, orgId) async {
      final stats = await ref
          .watch(organizationServiceProvider)
          .getAdminDashboardStats(orgId);

      final totalEmployees = stats['employees'] as int? ?? 0;
      final activeToday = stats['active_shifts'] as int? ?? 0;
      final attendanceAverage = totalEmployees > 0
          ? ((activeToday / totalEmployees) * 100).round()
          : 0;

      return OrganizationDashboardSnapshot(
        totalEmployees: totalEmployees,
        activeToday: activeToday,
        attendanceAverage: attendanceAverage,
      );
    });

/// Metricas enriquecidas por organizacion (asistencias y atrasos).
final organizationMetricsProvider =
    FutureProvider.autoDispose.family<OrganizationMetrics, String>((
  ref,
  orgId,
) async {
  return ref.watch(organizationServiceProvider).getOrganizationMetrics(orgId);
});

/// Plan y limites de la organizacion.
final organizationPlanProvider =
    FutureProvider.autoDispose.family<PlanSummary, String>((
  ref,
  orgId,
) async {
  return ref.watch(organizationServiceProvider).getPlanSummary(orgId);
});

/// Obtiene estadisticas globales (Solo SUPERADMIN)
final superAdminStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      return ref.watch(organizationServiceProvider).getSuperAdminStats();
    });

/// Configuracion global (fila unica)
final globalSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(globalSettingsServiceProvider).getSettings();
});

class GlobalSettingsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> save(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(globalSettingsServiceProvider).updateSettings(updates);
    });
  }
}

final globalSettingsControllerProvider =
    AsyncNotifierProvider<GlobalSettingsController, void>(
  GlobalSettingsController.new,
);


/// Controller para acciones de Super Admin (crear/editar orgs, roles, etc).
class SuperAdminController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<Organization?> createOrganization({
    required String name,
    String? contactEmail,
    OrgStatus status = OrgStatus.prueba,
  }) async {
    state = const AsyncValue.loading();
    final response = await AsyncValue.guard(() {
      return ref.read(organizationServiceProvider).createOrganization(
            name: name,
            contactEmail: contactEmail,
            status: status,
          );
    });
    state = response;
    return response.valueOrNull;
  }

  Future<Organization?> updateOrganization(
    String organizationId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();
    final response = await AsyncValue.guard(() {
      return ref
          .read(organizationServiceProvider)
          .updateOrganization(organizationId, updates);
    });
    state = response;
    return response.valueOrNull;
  }

  Future<Organization?> setOrganizationStatus(
    String organizationId,
    OrgStatus status,
  ) async {
    state = const AsyncValue.loading();
    final response = await AsyncValue.guard(() {
      return ref
          .read(organizationServiceProvider)
          .setOrganizationStatus(organizationId, status);
    });
    state = response;
    return response.valueOrNull;
  }

  Future<void> setOrgAdmin({
    required String userId,
    required bool isAdmin,
    String? organizationId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(organizationServiceProvider).setOrgAdmin(
            userId: userId,
            isAdmin: isAdmin,
            organizationId: organizationId,
          );
    });
  }

  Future<void> setOrgAdminByEmail({
    required String email,
    required String organizationId,
    bool isAdmin = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(organizationServiceProvider).setOrgAdminByEmail(
            email: email,
            organizationId: organizationId,
            isAdmin: isAdmin,
          );
    });
  }

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref
          .read(organizationServiceProvider)
          .setUserActive(userId: userId, isActive: isActive);
    });
  }

  Future<void> createOrgAdminUser({
    required String email,
    required String password,
    String? fullName,
    required String organizationId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(organizationServiceProvider).createOrgAdminUser(
            email: email,
            password: password,
            fullName: fullName,
            organizationId: organizationId,
          );
    });
  }
}

final superAdminControllerProvider =
    AsyncNotifierProvider<SuperAdminController, void>(
  SuperAdminController.new,
);

/// Controller para administración de organizaciones
class OrganizationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Crea un empleado en la organizacion del admin actual.
  Future<void> createEmployee({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizationId;
      if (orgId == null) {
        throw Exception('No se encontro organizacion para el admin.');
      }
      await ref.read(organizationServiceProvider).createEmployeeUser(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            organizationId: orgId,
          );
    });
  }

  /// Actualiza configuración de la organización (Admin)
  Future<void> updateOrgConfig(
    String orgId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(organizationServiceProvider).updateConfig(orgId, updates),
    );
  }
}

final organizationControllerProvider =
    AsyncNotifierProvider<OrganizationController, void>(
      OrganizationController.new,
    );

// ============================================================================
// 5. ASISTENCIA (ATTENDANCE TRACKING)
// ============================================================================
/// Obtiene el historial de asistencia del usuario
/// Incluye todos los turnos completados
final attendanceHistoryProvider = FutureProvider.autoDispose<List<WorkShift>>((
  ref,
) async {
  ref.watch(attendanceControllerProvider);
  return ref.watch(attendanceServiceProvider).getMyHistory();
});

/// Ubicacion GPS actual del empleado (una sola lectura con fallback interno)
final currentLocationProvider = FutureProvider.autoDispose<Position?>((ref) async {
  return LocationHelper.getCurrentLocation();
});

/// Obtiene estadísticas de hoy (horas trabajadas, etc.)
final todayStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  ref.watch(attendanceControllerProvider);
  return ref.watch(attendanceServiceProvider).getTodayStats();
});

/// Obtiene el turno activo actual (si existe)
/// Retorna null si no hay un turno activo
final activeShiftProvider = FutureProvider.autoDispose<WorkShift?>((ref) async {
  ref.watch(attendanceControllerProvider);
  return ref.watch(attendanceServiceProvider).getActiveShift();
});

/// Controller de asistencia - Maneja CheckIn y CheckOut
class AttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Registra entrada (CheckIn)
  /// Requiere: ubicación geográfica, foto del usuario y ID de la organización
  Future<void> checkIn({
    required GeoLocation location,
    required File photoFile,
    required String orgId,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserProvider)!.id;
      final storage = ref.read(storageServiceProvider);
      final service = ref.read(attendanceServiceProvider);

      // Sube la foto de entrada
      final photoPath = await storage.uploadEvidence(photoFile, userId, orgId);

      // Registra el CheckIn en la BD
      await service.checkIn(
        location: location,
        photoPath: photoPath,
        address: address,
      );

      // Invalida los providers relacionados para recargar datos
      ref.invalidate(activeShiftProvider);
      ref.invalidate(todayStatsProvider);
    });
  }

  /// Registra salida (CheckOut)
  /// Requiere: ID del turno activo, ubicación y opcionalmente foto
  Future<void> checkOut({
    required String shiftId,
    required GeoLocation location,
    required String orgId,
    File? photoFile,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(storageServiceProvider);
      final service = ref.read(attendanceServiceProvider);

      String? photoPath;
      if (photoFile != null) {
        final userId = ref.read(currentUserProvider)!.id;
        photoPath = await storage.uploadEvidence(photoFile, userId, orgId);
      }

      // Registra el CheckOut en la BD
      await service.checkOut(
        shiftId: shiftId,
        location: location,
        photoPath: photoPath,
        address: address,
      );

      // Invalida los providers relacionados para recargar datos
      ref.invalidate(activeShiftProvider);
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(todayStatsProvider);
    });
  }
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, void>(AttendanceController.new);

// ============================================================================
// 6. NOTIFICACIONES (NOTIFICATIONS)
// ============================================================================
/// Stream en tiempo real de notificaciones (usuario + organización).
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) async* {
      final profile = await ref.watch(profileProvider.future);
      final orgId = profile?.organizationId;
      yield* ref.watch(notificationServiceProvider).myNotificationsStream(
            orgId: orgId,
          );
    });

/// Cuenta de notificaciones no leídas
/// Se recalcula automáticamente cuando cambia el stream de notificaciones
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Controller de notificaciones - Maneja lectura y acciones
class NotificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Marca una notificación individual como leída
  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationServiceProvider).markAsRead(id),
    );
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationServiceProvider).markAllAsRead(),
    );
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(
      NotificationController.new,
    );

// ============================================================================
// 7. HORARIOS (SCHEDULES)
// ============================================================================
/// Obtiene el horario semanal del usuario
/// Incluye horarios generales y horarios personalizados si existen
final myScheduleProvider = FutureProvider.autoDispose<List<WorkSchedule>>((
  ref,
) async {
  return ref.watch(scheduleServiceProvider).getMySchedule();
});

/// Controller para administración de horarios (Admin)
class ScheduleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Asigna un horario a un empleado
  Future<void> createSchedule(WorkSchedule schedule) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(scheduleServiceProvider).createSchedule(schedule),
    );
  }
}

final scheduleControllerProvider =
    AsyncNotifierProvider<ScheduleController, void>(ScheduleController.new);

// ============================================================================
// 8. BIOMETRÍA (BIOMETRIC AUTHENTICATION)
// ============================================================================
/// Verifica si el dispositivo soporta autenticación biométrica
final biometricAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  return ref.watch(biometricServiceProvider).isBiometricAvailable();
});

/// Controller para autenticación biométrica
class BiometricController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Autentica mediante biometría (huella o reconocimiento facial)
  Future<void> authenticate() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(biometricServiceProvider).authenticate(),
    );
  }
}

final biometricControllerProvider =
    AsyncNotifierProvider<BiometricController, void>(BiometricController.new);
