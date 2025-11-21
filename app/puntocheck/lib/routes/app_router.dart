import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importamos los providers para verificar autenticación y permisos
import '../providers/app_providers.dart';

// ============================================================================
// IMPORTACIÓN DE VISTAS - AUTENTICACIÓN Y VISTAS PÚBLICAS
// ============================================================================
import '../presentation/splash/views/splash_view.dart';
import '../presentation/login/login_view.dart';
import '../presentation/login/register_view.dart';
import '../presentation/login/forgot_password_email_view.dart';
import '../presentation/login/forgot_password_code_view.dart';
import '../presentation/login/reset_password_view.dart';
import '../presentation/login/reset_password_success_view.dart';

// ============================================================================
// IMPORTACIÓN DE VISTAS - ROL: EMPLEADO
// ============================================================================
import '../presentation/employee/views/employee_home_view.dart';
import '../presentation/employee/views/registro_asistencia_view.dart';
import '../presentation/employee/views/horario_trabajo_view.dart';
import '../presentation/employee/views/historial_view.dart';
import '../presentation/employee/views/avisos_view.dart';
import '../presentation/employee/views/settings_view.dart';
import '../presentation/employee/views/personal_info_view.dart';

// ============================================================================
// IMPORTACIÓN DE VISTAS - ROL: ADMIN DE EMPRESA
// ============================================================================
import '../presentation/admin/views/admin_shell_view.dart';
import '../presentation/admin/views/nuevo_empleado_view.dart';
import '../presentation/admin/views/empleados_list_view.dart';
import '../presentation/admin/views/empleado_detalle_view.dart';
import '../presentation/admin/views/horario_admin_view.dart';
import '../presentation/admin/views/anuncios_admin_view.dart';
import '../presentation/admin/views/nuevo_anuncio_view.dart';
import '../presentation/admin/views/apariencia_app_view.dart';

// ============================================================================
// IMPORTACIÓN DE VISTAS - ROL: SUPER ADMIN (SaaS)
// ============================================================================
import '../presentation/superadmin/views/super_admin_shell_view.dart';
import '../presentation/superadmin/views/organizaciones_list_view.dart';
import '../presentation/superadmin/views/organizacion_detalle_view.dart';
import '../presentation/superadmin/views/config_global_view.dart';

// ============================================================================
// CONFIGURACIÓN GLOBAL DE NAVEGACIÓN
// ============================================================================
/// Llave global para acceder al NavigatorState desde cualquier lado de la app
/// Útil para operaciones complejas de navegación o alertas globales
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ============================================================================
// PROVIDER PRINCIPAL: GO_ROUTER
// ============================================================================
/// Provider que configura y proporciona la instancia de GoRouter
/// Observa el estado de autenticación y perfil para aplicar redirects
/// y proteger rutas según los permisos del usuario
final appRouterProvider = Provider<GoRouter>((ref) {
  // Observamos el estado de autenticación (Stream)
  final authState = ref.watch(authStateProvider);
  
  // Observamos el perfil del usuario (con su rol)
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,

    // ========================================================================
    // LÓGICA DE REDIRECCIÓN (GUARDRAILS & PROTECCIÓN DE RUTAS)
    // ========================================================================
    redirect: (context, state) {
      // Rutas públicas que no requieren autenticación
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/';
      final isRegistering = state.matchedLocation == '/register';
      final isRecovering = state.matchedLocation.startsWith('/forgot');
      final isPublicRoute = isLoggingIn || isSplashing || isRegistering || isRecovering;

      // ====================================================================
      // PASO 1: VERIFICAR ESTADO DE AUTENTICACIÓN
      // ====================================================================
      // Si Auth está cargando, no redirigir (mantener en splash)
      if (authState.isLoading) {
        return null;
      }

      // Si hay error en Auth, quedarse quieto
      if (authState.hasError) {
        return null;
      }

      // Determinar si el usuario tiene sesión activa
      final isLoggedIn = authState.value?.session != null;

      // ====================================================================
      // PASO 2: USUARIO NO LOGUEADO - Bloquear acceso a rutas privadas
      // ====================================================================
      if (!isLoggedIn) {
        // Permitir acceso a rutas públicas (login, registro, recuperación)
        if (isPublicRoute) {
          return null;
        }
        // Bloquear acceso a rutas privadas y redirigir a login
        return '/login';
      }

      // ====================================================================
      // PASO 3: USUARIO LOGUEADO - Verificar y cargar perfil
      // ====================================================================
      // Si el perfil está cargando, mantener al usuario donde está
      // (O redirigir a splash si aún no ha llegado a ningún lado)
      if (profileState.isLoading) {
        if (!isSplashing) {
          return '/';
        }
        return null;
      }

      // Si hay error cargando el perfil, quedarse quieto
      // (El UI puede mostrar un error)
      if (profileState.hasError) {
        return null;
      }

      final profile = profileState.value;
      if (profile == null) {
        return null;
      }

      // ====================================================================
      // PASO 4: USUARIO LOGUEADO CON PERFIL CARGADO
      // Redirigir desde splash/login al dashboard correspondiente
      // ====================================================================
      if (isPublicRoute && isLoggedIn) {
        // Redirigir al dashboard según rol
        if (profile.isSuperAdmin) {
          return '/superadmin/home';
        }
        if (profile.isOrgAdmin) {
          return '/admin/home';
        }
        return '/employee/home';
      }

      // ====================================================================
      // PASO 5: PROTECCIÓN DE RUTAS POR ROL
      // Bloquear acceso a rutas donde el usuario no tiene permisos
      // ====================================================================
      final currentPath = state.matchedLocation;

      // Solo Admins y SuperAdmins pueden acceder a /admin
      if (currentPath.startsWith('/admin')) {
        if (!profile.isOrgAdmin && !profile.isSuperAdmin) {
          return '/employee/home';
        }
      }

      // Solo SuperAdmins pueden acceder a /superadmin
      if (currentPath.startsWith('/superadmin')) {
        if (!profile.isSuperAdmin) {
          // Redirigir al dashboard correspondiente según rol
          return profile.isOrgAdmin ? '/admin/home' : '/employee/home';
        }
      }

      // ====================================================================
      // PASO 6: PERMITIR NAVEGACIÓN
      // Si todo está OK, permitir que continúe
      // ====================================================================
      return null;
    },

    // ========================================================================
    // DEFINICIÓN DE RUTAS
    // ========================================================================
    routes: [
      // ====================================================================
      // RUTAS PÚBLICAS (Splash, Login, Register, Password Recovery)
      // ====================================================================
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashView(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot/email',
        name: 'forgotPasswordEmail',
        builder: (_, __) => const ForgotPasswordEmailView(),
      ),
      GoRoute(
        path: '/forgot/code',
        name: 'forgotPasswordCode',
        builder: (_, __) => const ForgotPasswordCodeView(),
      ),
      GoRoute(
        path: '/forgot/reset',
        name: 'resetPassword',
        builder: (_, __) => const ResetPasswordView(),
      ),
      GoRoute(
        path: '/forgot/success',
        name: 'resetPasswordSuccess',
        builder: (_, __) => const ResetPasswordSuccessView(),
      ),

      // ====================================================================
      // RUTAS - ROL: EMPLEADO
      // ====================================================================
      GoRoute(
        path: '/employee/home',
        name: 'employeeHome',
        builder: (_, __) => const EmployeeHomeView(),
        routes: [
          // Registro de asistencia (Check-in / Check-out)
          GoRoute(
            path: 'registro-asistencia',
            name: 'registroAsistencia',
            builder: (_, __) => const RegistroAsistenciaView(),
          ),
          // Horario de trabajo del empleado
          GoRoute(
            path: 'horario-trabajo',
            name: 'horarioTrabajo',
            builder: (_, __) => const HorarioTrabajoView(),
          ),
          // Historial de asistencia
          GoRoute(
            path: 'historial',
            name: 'historial',
            builder: (_, __) => const HistorialView(),
          ),
          // Avisos/Notificaciones
          GoRoute(
            path: 'avisos',
            name: 'avisos',
            builder: (_, __) => const AvisosView(),
          ),
          // Configuración de la app
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (_, __) => const SettingsView(),
          ),
          // Información personal del empleado
          GoRoute(
            path: 'personal-info',
            name: 'personalInfo',
            builder: (_, __) => const PersonalInfoView(),
          ),
        ],
      ),

      // ====================================================================
      // RUTAS - ROL: ADMIN DE EMPRESA
      // ====================================================================
      GoRoute(
        path: '/admin/home',
        name: 'adminHome',
        builder: (_, __) => const AdminShellView(),
        routes: [
          // Crear nuevo empleado
          GoRoute(
            path: 'nuevo-empleado',
            name: 'nuevoEmpleado',
            builder: (_, __) => const NuevoEmpleadoView(),
          ),
          // Listar todos los empleados
          GoRoute(
            path: 'empleados',
            name: 'empleados',
            builder: (_, __) => const EmpleadosListView(),
          ),
          // Detalle de un empleado específico (con parámetro dinámico)
          GoRoute(
            path: 'empleado-detalle/:id',
            name: 'empleadoDetalle',
            builder: (context, state) {
              // El ID del empleado está disponible en state.pathParameters['id']
              // Puedes pasarlo a la vista si es necesario
              return const EmpleadoDetalleView();
            },
          ),
          // Gestión de horarios
          GoRoute(
            path: 'horario',
            name: 'horarioAdmin',
            builder: (_, __) => const HorarioAdminView(),
          ),
          // Lista de anuncios/comunicados
          GoRoute(
            path: 'anuncios',
            name: 'anunciosAdmin',
            builder: (_, __) => const AnunciosAdminView(),
          ),
          // Crear nuevo anuncio
          GoRoute(
            path: 'anuncios/nuevo',
            name: 'nuevoAnuncio',
            builder: (_, __) => const NuevoAnuncioView(),
          ),
          // Configuración de apariencia de la app
          GoRoute(
            path: 'apariencia-app',
            name: 'aparienciaApp',
            builder: (_, __) => const AparienciaAppView(),
          ),
        ],
      ),

      // ====================================================================
      // RUTAS - ROL: SUPER ADMIN (Gestor del SaaS)
      // ====================================================================
      GoRoute(
        path: '/superadmin/home',
        name: 'superadminHome',
        builder: (_, __) => const SuperAdminShellView(),
        routes: [
          // Listar todas las organizaciones
          GoRoute(
            path: 'organizaciones',
            name: 'organizaciones',
            builder: (_, __) => const OrganizacionesListView(),
          ),
          // Detalle de una organización
          GoRoute(
            path: 'organizacion-detalle',
            name: 'organizacionDetalle',
            builder: (_, __) => const OrganizacionDetalleView(),
          ),
          // Configuración global del SaaS
          GoRoute(
            path: 'config-global',
            name: 'configGlobal',
            builder: (_, __) => const ConfigGlobalView(),
          ),
        ],
      ),
    ],
  );
});