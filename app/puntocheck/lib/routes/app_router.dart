import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/providers/app_providers.dart';

// Login
import 'package:puntocheck/presentation/login/login_view.dart';
import 'package:puntocheck/presentation/login/forgot_password_email_view.dart';
import 'package:puntocheck/presentation/login/forgot_password_code_view.dart';
import 'package:puntocheck/presentation/login/reset_password_view.dart';
import 'package:puntocheck/presentation/login/reset_password_success_view.dart';

// Splash
import 'package:puntocheck/presentation/splash/views/splash_view.dart';

// Admin
import 'package:puntocheck/presentation/admin/views/admin_shell_view.dart';
import 'package:puntocheck/presentation/admin/views/nuevo_empleado_view.dart';
import 'package:puntocheck/presentation/admin/views/empleados_list_view.dart';
import 'package:puntocheck/presentation/admin/views/empleado_detalle_view.dart';
import 'package:puntocheck/presentation/admin/views/anuncios_admin_view.dart';
import 'package:puntocheck/presentation/admin/views/nuevo_anuncio_view.dart';

// Employee
import 'package:puntocheck/presentation/employee/views/employee_home_view.dart';
import 'package:puntocheck/presentation/employee/views/horario_trabajo_view.dart';
import 'package:puntocheck/presentation/employee/views/registro_asistencia_view.dart';
import 'package:puntocheck/presentation/employee/views/settings_view.dart';
import 'package:puntocheck/presentation/employee/views/personal_info_view.dart';

// SuperAdmin
import 'package:puntocheck/presentation/superadmin/views/super_admin_shell_view.dart';
import 'package:puntocheck/presentation/superadmin/views/organizaciones_list_view.dart';
import 'package:puntocheck/presentation/superadmin/views/organizacion_detalle_view.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotEmail = '/forgot-email';
  static const String forgotCode = '/forgot-code';
  static const String resetPassword = '/reset-password';
  static const String resetPasswordSuccess = '/reset-password-success';

  // Admin
  static const String adminHome = '/admin';
  static const String adminNuevoEmpleado = '/admin/nuevo-empleado';
  static const String adminEmpleadosList = '/admin/empleados';
  static const String adminEmpleadoDetalle = '/admin/empleado-detalle';
  static const String adminAnuncios = '/admin/anuncios';
  static const String adminNuevoAnuncio = '/admin/nuevo-anuncio';

  // Employee
  static const String employeeHome = '/employee';
  static const String horarioTrabajo = '/employee/horario';
  static const String registroAsistencia = '/employee/asistencia';
  static const String personalInfo = '/employee/personal-info';
  static const String settings = '/employee/settings';

  // SuperAdmin
  static const String superAdminHome = '/superadmin';
  static const String superAdminOrganizaciones = '/superadmin/organizaciones';
  static const String superAdminOrganizacionDetalle =
      '/superadmin/organizacion-detalle';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Observar cambios en el perfil del usuario para actualizar el router
  ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final path = state.uri.path;
      final isLoggingIn = path == AppRoutes.login;
      final isForgotFlow =
          path.startsWith('/forgot') || path.startsWith('/reset');
      final isSplash = path == AppRoutes.splash;

      if (!isLoggedIn) {
        return (isLoggingIn || isSplash || isForgotFlow)
            ? null
            : AppRoutes.login;
      }

      final role = ref.read(userRoleProvider);
      if (role == UserRole.unknown) {
        return null;
      }

      String roleHome;
      switch (role) {
        case UserRole.superAdmin:
          roleHome = AppRoutes.superAdminHome;
          break;
        case UserRole.admin:
          roleHome = AppRoutes.adminHome;
          break;
        case UserRole.employee:
        default:
          roleHome = AppRoutes.employeeHome;
          break;
      }

      final isOnRolePath = path == roleHome || path.startsWith('$roleHome/');

      if (isLoggingIn || isSplash) {
        return roleHome;
      }

      if (!isOnRolePath && !isForgotFlow) {
        return roleHome;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashView()),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/forgot-email',
        builder: (context, state) => const ForgotPasswordEmailView(),
      ),
      GoRoute(
        path: '/forgot-code',
        builder: (context, state) => const ForgotPasswordCodeView(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordView(),
      ),
      GoRoute(
        path: '/reset-password-success',
        builder: (context, state) => const ResetPasswordSuccessView(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShellView(),
        routes: [
          GoRoute(
            path: 'nuevo-empleado',
            builder: (context, state) => const NuevoEmpleadoView(),
          ),
          GoRoute(
            path: 'empleados',
            builder: (context, state) => const EmpleadosListView(),
          ),
          GoRoute(
            path: 'empleado-detalle',
            builder: (context, state) {
              final employee = state.extra;
              return EmpleadoDetalleView(employee: employee);
            },
          ),
          GoRoute(
            path: 'anuncios',
            builder: (context, state) => const AnunciosAdminView(),
          ),
          GoRoute(
            path: 'nuevo-anuncio',
            builder: (context, state) => const NuevoAnuncioView(),
          ),
        ],
      ),

      // Employee Routes
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeHomeView(),
        routes: [
          GoRoute(
            path: 'horario',
            builder: (context, state) => const HorarioTrabajoView(),
          ),
          GoRoute(
            path: 'asistencia',
            builder: (context, state) => const RegistroAsistenciaView(),
          ),
          GoRoute(
            path: 'personal-info',
            builder: (context, state) => const PersonalInfoView(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),

      // SuperAdmin Routes
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperAdminShellView(),
        routes: [
          GoRoute(
            path: 'organizaciones',
            builder: (context, state) => const OrganizacionesListView(),
          ),
          GoRoute(
            path: 'organizacion-detalle',
            builder: (context, state) {
              final org = state.extra as Organization?;
              return OrganizacionDetalleView(organization: org);
            },
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
