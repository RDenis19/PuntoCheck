import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/login/views/login_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_shell_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_shell_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_shell_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_alerts_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branches_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_edit_org_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_hours_bank_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_leaves_hours_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_legal_config_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_payments_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_schedule_assignments_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_schedules_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_shell_view.dart';
import 'package:puntocheck/presentation/kiosk/views/device_kiosk_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_shell_view.dart';
import 'package:puntocheck/presentation/splash/views/splash_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_org_detail_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_org_staff_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_org_payments_view.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';

  static const superAdminHome = '/super-admin';
  static const orgAdminHome = '/org-admin';
  static const managerHome = '/manager';
  static const auditorHome = '/auditor';
  static const employeeHome = '/employee';
  static const orgAdminEditOrg = '$orgAdminHome/edit-org';
  static const orgAdminBranches = '$orgAdminHome/branches';
  static const orgAdminPayments = '$orgAdminHome/payments';
  static const orgAdminAlerts = '$orgAdminHome/alerts';
  static const orgAdminSchedules = '$orgAdminHome/schedules';
  static const orgAdminScheduleAssignments =
      '$orgAdminHome/schedule-assignments';
  static const orgAdminHoursBank = '$orgAdminHome/hours-bank';
  static const orgAdminLeaves = '$orgAdminHome/leaves';
  static const orgAdminLegalConfig = '$orgAdminHome/legal-config';
  static const orgAdminKiosk = '$orgAdminHome/kiosk';

  static String homeForRole(RolUsuario role) {
    switch (role) {
      case RolUsuario.superAdmin:
        return AppRoutes.superAdminHome;
      case RolUsuario.orgAdmin:
        return AppRoutes.orgAdminHome;
      case RolUsuario.manager:
        return AppRoutes.managerHome;
      case RolUsuario.auditor:
        return AppRoutes.auditorHome;
      case RolUsuario.employee:
        return AppRoutes.employeeHome;
    }
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.read(authServiceProvider).authStateChanges;
  final refresher = GoRouterRefreshStream(authStream);
  ref.onDispose(refresher.dispose);

  // Forzar refresh cuando el perfil pasa de loading -> data/error.
  ref.listen<AsyncValue<Perfiles?>>(profileProvider, (_, __) {
    refresher.refresh();
  });
  ref.listen<bool>(authSessionTransitionProvider, (_, __) {
    refresher.refresh();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    // Escucha cambios de sesión para recalcular redirect sin necesitar hot-reload.
    refreshListenable: refresher,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profileAsync = ref.read(profileProvider);
      final isAuthTransitioning = ref.read(authSessionTransitionProvider);

      final session =
          authState.asData?.value.session ??
          Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final path = state.uri.toString();

      final isAuthFlow = path == AppRoutes.login;
      final isSplash = path == AppRoutes.splash;

      if (isAuthTransitioning) {
        return null;
      }

      if (!isLoggedIn) {
        return isAuthFlow ? null : AppRoutes.login;
      }

      if (profileAsync.isLoading) {
        // Evita loop en splash/login mientras carga el perfil.
        return null;
      }

      if (profileAsync.hasError) return AppRoutes.login;
      final profile = profileAsync.asData?.value;
      final role = profile?.rol;
      if (profile == null || role == null) return AppRoutes.login;

      final roleHome = AppRoutes.homeForRole(role);
      final isOnRolePath = path == roleHome || path.startsWith('$roleHome/');

      if (isSplash || isAuthFlow) return roleHome;
      if (!isOnRolePath) return roleHome;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashView()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginView()),
      GoRoute(
        path: AppRoutes.superAdminHome,
        builder: (_, __) => const SuperAdminShellView(),
      ),
      GoRoute(
        path: '${AppRoutes.superAdminHome}/org/:orgId',
        builder: (_, state) =>
            SuperAdminOrgDetailView(orgId: state.pathParameters['orgId'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.superAdminHome}/org/:orgId/staff',
        builder: (_, state) =>
            SuperAdminOrgStaffView(orgId: state.pathParameters['orgId'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.superAdminHome}/org/:orgId/payments',
        builder: (_, state) => SuperAdminOrgPaymentsView(
          orgId: state.pathParameters['orgId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.orgAdminHome,
        builder: (_, __) => const OrgAdminShellView(),
        routes: [
          GoRoute(
            path: 'edit-org',
            builder: (_, __) => const OrgAdminEditOrgView(),
          ),
          GoRoute(
            path: 'branches',
            builder: (_, __) => const OrgAdminBranchesView(),
          ),
          GoRoute(
            path: 'payments',
            builder: (_, __) => const OrgAdminPaymentsView(),
          ),
          GoRoute(
            path: 'alerts',
            builder: (_, __) => const OrgAdminAlertsView(),
          ),
          GoRoute(
            path: 'schedules',
            builder: (_, __) => const OrgAdminSchedulesView(),
          ),
          GoRoute(
            path: 'schedule-assignments',
            builder: (_, __) => const OrgAdminScheduleAssignmentsView(),
          ),
          GoRoute(
            path: 'hours-bank',
            builder: (_, __) => const OrgAdminHoursBankView(),
          ),
          GoRoute(
            path: 'leaves',
            builder: (_, __) => const OrgAdminLeavesAndHoursView(),
          ),
          GoRoute(
            path: 'legal-config',
            builder: (_, __) => const OrgAdminLegalConfigView(),
          ),
          GoRoute(path: 'kiosk', builder: (_, __) => const DeviceKioskView()),
        ],
      ),
      GoRoute(
        path: AppRoutes.managerHome,
        builder: (_, __) => const ManagerShellView(),
      ),
      GoRoute(
        path: AppRoutes.auditorHome,
        builder: (_, __) => const AuditorShellView(),
      ),
      GoRoute(
        path: AppRoutes.employeeHome,
        builder: (_, __) => const EmployeeShellView(),
      ),
    ],
  );
});

/// Notificador simple para refrescar GoRouter cuando cambia un stream (ej: auth).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
