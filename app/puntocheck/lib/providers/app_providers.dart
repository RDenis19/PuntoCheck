// lib/providers/app_providers.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/pagos_suscripciones.dart';
import '../models/perfiles.dart';
import '../models/planes_suscripcion.dart';
import '../models/super_admin_dashboard.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/registros_asistencia.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/compliance_service.dart';
import '../services/operations_service.dart';
import '../services/organization_service.dart';
import '../services/staff_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../services/payments_service.dart';
import '../services/super_admin_service.dart';
import '../utils/theme/app_theme.dart';
import '../utils/theme/brand_theme.dart';

/// Punto unico para registrar todos los providers y controladores.
/// Consumir servicios aqui evita que la UI tenga dependencias directas.

// ============================================================================
// 1. SUPABASE Y SERVICIOS CORE
// ============================================================================
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService.instance;
});

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  return PaymentsService.instance;
});

final organizationServiceProvider = Provider<OrganizationService>((ref) {
  return OrganizationService.instance;
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService.instance;
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService.instance;
});

final complianceServiceProvider = Provider<ComplianceService>((ref) {
  return ComplianceService.instance;
});

final operationsServiceProvider = Provider<OperationsService>((ref) {
  return OperationsService.instance;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService.instance;
});

// ============================================================================
// 2. AUTH
// ============================================================================
/// Stream del estado de autenticacion (login/logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Usuario actual (nullable).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user ??
      Supabase.instance.client.auth.currentUser;
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(email, password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

// ============================================================================
// 3. PERFIL Y ROLES
// ============================================================================
final profileProvider = FutureProvider<Perfiles?>((ref) async {
  // Se vuelve a ejecutar cada vez que cambia el estado de auth.
  final authState = ref.watch(authStateProvider);
  final session =
      authState.asData?.value.session ?? Supabase.instance.client.auth.currentSession;
  final user = session?.user;
  if (user == null) return null;
  final service = ref.watch(authServiceProvider);
  final result = await service.getFullUserProfile();
  return result['perfil'] as Perfiles?;
});

final userRoleProvider = Provider<RolUsuario?>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.asData?.value?.rol;
});

// ============================================================================
// 4. THEME (BRANDING)
// ============================================================================
class BrandThemeController extends StateNotifier<BrandTheme> {
  BrandThemeController() : super(BrandTheme.red());

  void applyPrimary(Color primary, {Color? onPrimary}) {
    state = state.copyWith(primary: primary, onPrimary: onPrimary);
  }

  void applyOrgPalette({
    required Color primary,
    Color? secondary,
    Color? onPrimary,
    Color? onSecondary,
  }) {
    state = state.copyWith(
      primary: primary,
      onPrimary: onPrimary ?? state.onPrimary,
      secondary: secondary ?? state.secondary,
      onSecondary: onSecondary ?? state.onSecondary,
    );
  }

  void resetToDefault() {
    state = BrandTheme.red();
  }
}

final brandThemeProvider =
    StateNotifierProvider<BrandThemeController, BrandTheme>(
      (ref) => BrandThemeController(),
    );

/// ThemeData consumido por MaterialApp con la paleta activa.
final appThemeProvider = Provider<ThemeData>((ref) {
  final brand = ref.watch(brandThemeProvider);
  return AppTheme.fromBrand(brand);
});

// ============================================================================
// 5. SUPER ADMIN: DATA SOURCES
// ============================================================================
final superAdminDashboardProvider =
    FutureProvider.autoDispose<SuperAdminDashboardData>((ref) {
      final service = ref.watch(superAdminServiceProvider);
      return service.loadDashboard();
    });

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<PlanesSuscripcion>>((ref) {
      return ref.watch(subscriptionServiceProvider).getPlans();
    });

final pendingPaymentsProvider =
    FutureProvider.autoDispose<List<PagosSuscripciones>>((ref) {
      return ref.watch(paymentsServiceProvider).listPendingPayments();
    });

final organizationDetailProvider =
    FutureProvider.family<Organizaciones, String>((ref, orgId) {
      return ref.watch(organizationServiceProvider).getOrganizationById(orgId);
    });

final organizationPaymentsProvider = FutureProvider.autoDispose
    .family<List<PagosSuscripciones>, String>((ref, orgId) {
      return ref.watch(paymentsServiceProvider).listPayments(orgId: orgId);
    });

final allPaymentsProvider =
    FutureProvider.autoDispose<List<PagosSuscripciones>>((ref) {
      return ref.watch(paymentsServiceProvider).listPayments();
    });

final organizationStaffProvider = FutureProvider.family<List<Perfiles>, String>(
  (ref, orgId) async {
    final staff = await ref.watch(staffServiceProvider).getStaff(orgId);
    staff.sort((a, b) {
      final aDate = a.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.creadoEn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return staff;
  },
);

/// Cumplimiento LOE por organización (alertas, riesgos, etc.).
/// Ajusta el nombre del método del servicio según tu implementación real.
final orgComplianceAlertsProvider =
    FutureProvider.family<List<AlertasCumplimiento>, String>((ref, orgId) {
      final service = ref.watch(complianceServiceProvider);
      return service.getAlerts(orgId, onlyPending: true);
    });

/// Actividad reciente de asistencia por organización (soporte nivel 3).
/// Ajusta el método y parámetros según tu AttendanceService.
final orgRecentAttendanceProvider =
    FutureProvider.family<List<RegistrosAsistencia>, String>((ref, orgId) {
      final service = ref.watch(attendanceServiceProvider);
      return service.getRecentByOrg(orgId, limit: 10);
    });

/// Logs generales recientes para soporte (usa RLS segun rol).
final supportRecentAttendanceProvider =
    FutureProvider.autoDispose<List<RegistrosAsistencia>>((ref) {
      final service = ref.watch(operationsServiceProvider);
      return service.getAttendanceLogs(limit: 10);
    });

// ============================================================================
// 6. SUPER ADMIN: CONTROLADORES DE ACCION
// ============================================================================
class PlanEditorController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createPlan(PlanesSuscripcion plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionServiceProvider).createPlan(plan),
    );
    if (!state.hasError) {
      ref
        ..invalidate(subscriptionPlansProvider)
        ..invalidate(superAdminDashboardProvider);
    }
  }

  Future<void> updatePlan(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionServiceProvider).updatePlan(id, updates),
    );
    if (!state.hasError) {
      ref
        ..invalidate(subscriptionPlansProvider)
        ..invalidate(superAdminDashboardProvider);
    }
  }
}

final planEditorControllerProvider =
    AsyncNotifierProvider<PlanEditorController, void>(PlanEditorController.new);

class PaymentValidationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> approve(String pagoId, {String? notes}) {
    return _validate(pagoId, EstadoPago.aprobado, notes);
  }

  Future<void> reject(String pagoId, {String? notes}) {
    return _validate(pagoId, EstadoPago.rechazado, notes);
  }

  Future<void> _validate(
    String pagoId,
    EstadoPago estado,
    String? notes,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(paymentsServiceProvider)
          .updatePaymentStatus(
            pagoId: pagoId,
            nuevoEstado: estado,
            observaciones: notes,
          ),
    );

    if (!state.hasError) {
      ref
        ..invalidate(pendingPaymentsProvider)
        ..invalidate(superAdminDashboardProvider)
        ..invalidate(allPaymentsProvider);
    }
  }
}

final paymentValidationControllerProvider =
    AsyncNotifierProvider<PaymentValidationController, void>(
      PaymentValidationController.new,
    );

class OrganizationLifecycleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> assignPlan({
    required String orgId,
    required String planId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(organizationServiceProvider)
          .assignPlan(
            orgId: orgId,
            planId: planId,
            startDate: startDate,
            endDate: endDate,
          ),
    );
    if (!state.hasError) {
      _refreshOrg(orgId);
    }
  }

  Future<void> updateStatus({
    required String orgId,
    required EstadoSuscripcion estado,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(organizationServiceProvider)
          .updateSubscriptionStatus(orgId, estado),
    );
    if (!state.hasError) {
      _refreshOrg(orgId);
    }
  }

  void _refreshOrg(String orgId) {
    ref
      ..invalidate(organizationDetailProvider(orgId))
      ..invalidate(superAdminDashboardProvider);
  }
}

final organizationLifecycleControllerProvider =
    AsyncNotifierProvider<OrganizationLifecycleController, void>(
      OrganizationLifecycleController.new,
    );

class OrganizationCreationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createOrganizationWithAdmin({
    required String ruc,
    required String razonSocial,
    required String planId,
    String? logoUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(organizationServiceProvider)
          .createOrganization(
            ruc: ruc,
            razonSocial: razonSocial,
            planId: planId,
            logoUrl: logoUrl,
          ),
    );

    if (!state.hasError) {
      ref.invalidate(superAdminDashboardProvider);
    }
  }
}

final organizationCreationControllerProvider =
    AsyncNotifierProvider<OrganizationCreationController, void>(
      OrganizationCreationController.new,
    );

class OrganizationEditController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> updateOrganization({
    required String orgId,
    String? ruc,
    String? razonSocial,
    String? logoUrl,
    String? planId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(organizationServiceProvider)
          .updateOrganization(
            orgId: orgId,
            ruc: ruc,
            razonSocial: razonSocial,
            logoUrl: logoUrl,
            planId: planId,
          ),
    );
    if (!state.hasError) {
      ref
        ..invalidate(superAdminDashboardProvider)
        ..invalidate(organizationDetailProvider(orgId));
    }
  }
}

final organizationEditControllerProvider =
    AsyncNotifierProvider<OrganizationEditController, void>(
      OrganizationEditController.new,
    );

class PaymentCreationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> createPayment({
    required String orgId,
    required String planId,
    required double monto,
    required String comprobanteUrl,
    String? referencia,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(paymentsServiceProvider)
          .createPayment(
            orgId: orgId,
            planId: planId,
            monto: monto,
            comprobanteUrl: comprobanteUrl,
            referencia: referencia,
          ),
    );

    if (!state.hasError) {
      ref
        ..invalidate(organizationPaymentsProvider(orgId))
        ..invalidate(superAdminDashboardProvider)
        ..invalidate(pendingPaymentsProvider);
    }
  }
}

final paymentCreationControllerProvider =
    AsyncNotifierProvider<PaymentCreationController, void>(
      PaymentCreationController.new,
    );
