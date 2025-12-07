import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alertas_cumplimiento.dart';
import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/pagos_suscripciones.dart';
import '../models/perfiles.dart';
import '../models/planes_suscripcion.dart';
import '../models/registros_asistencia.dart';
import '../models/super_admin_dashboard.dart';
import 'core_providers.dart';

// ============================================================================
// Super Admin: data sources
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
  (ref, orgId) {
    return ref.watch(staffServiceProvider).getStaff(orgId);
  },
);

/// Cumplimiento LOE por organizacion (alertas, riesgos, etc.).
final orgComplianceAlertsProvider =
    FutureProvider.family<List<AlertasCumplimiento>, String>((ref, orgId) {
      final service = ref.watch(complianceServiceProvider);
      return service.getAlerts(orgId, onlyPending: true);
    });

/// Actividad reciente de asistencia por organizacion (soporte nivel 3).
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
// Super Admin: controladores de accion
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
