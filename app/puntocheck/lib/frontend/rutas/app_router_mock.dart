import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/vistas/admin/admin_shell_view.dart';
import 'package:puntocheck/frontend/vistas/admin/anuncios_admin_view.dart';
import 'package:puntocheck/frontend/vistas/admin/apariencia_app_view.dart';
import 'package:puntocheck/frontend/vistas/admin/empleado_detalle_view.dart';
import 'package:puntocheck/frontend/vistas/admin/empleados_list_view.dart';
import 'package:puntocheck/frontend/vistas/admin/horario_admin_view.dart';
import 'package:puntocheck/frontend/vistas/admin/nuevo_anuncio_view.dart';
import 'package:puntocheck/frontend/vistas/admin/nuevo_empleado_view.dart';
import 'package:puntocheck/frontend/vistas/auth/forgot_password_email_view.dart';
import 'package:puntocheck/frontend/vistas/auth/login_view.dart';
import 'package:puntocheck/frontend/vistas/auth/register_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/avisos_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/employee_home_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/historial_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/horario_trabajo_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/personal_info_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/registro_asistencia_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/settings_view.dart';
import 'package:puntocheck/frontend/vistas/splash/splash_view.dart';
import 'package:puntocheck/frontend/vistas/auth/forgot_password_code_view.dart';
import 'package:puntocheck/frontend/vistas/auth/reset_password_view.dart';
import 'package:puntocheck/frontend/vistas/auth/reset_password_success_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/config_global_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/organizacion_detalle_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/organizaciones_list_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/super_admin_home_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/super_admin_shell_view.dart';

/// Rutas nombradas para la navegación de la aplicación (mock).
abstract final class AppRouterMock {
  // Rutas de autenticación
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotEmail = '/forgot/email';
  static const String forgotCode = '/forgot/code';
  static const String resetPassword = '/forgot/reset';
  static const String resetPasswordSuccess = '/forgot/success';

  // Rutas de roles
  static const String employeeHome = '/employee/home';
  static const String employeeRegistroAsistencia =
      '/employee/registro-asistencia';
  static const String employeeHorarioTrabajo = '/employee/horario-trabajo';
  static const String employeeHistorial = '/employee/historial';
  static const String employeeAvisos = '/employee/avisos';
  static const String employeeSettings = '/employee/settings';
  static const String employeePersonalInfo = '/employee/personal-info';
  static const String adminHome = '/admin/home';
  static const String adminNuevoEmpleado = '/admin/nuevo-empleado';
  static const String adminEmpleadosList = '/admin/empleados';
  static const String adminEmpleadoDetalle = '/admin/empleado-detalle';
  static const String adminHorario = '/admin/horario';
  static const String adminAnuncios = '/admin/anuncios';
  static const String adminNuevoAnuncio = '/admin/anuncios/nuevo';
  static const String adminAparienciaApp = '/admin/apariencia-app';
  static const String superAdminHome = '/superadmin/home';
  static const String superAdminOrganizaciones = '/superadmin/organizaciones';
  static const String superAdminOrganizacionDetalle =
      '/superadmin/organizacion-detalle';
  static const String superAdminConfigGlobal = '/superadmin/config-global';

  /// Generador de rutas para MaterialApp.
  ///
  /// TODO(backend): Aquí se pueden añadir redirecciones basadas en token/sesión persistida
  /// para proteger las rutas de acuerdo a rol y permisos.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashView());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterView());
      case forgotEmail:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordEmailView(),
        );
      case forgotCode:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordCodeView(),
        );
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordView());
      case resetPasswordSuccess:
        return MaterialPageRoute(
          builder: (_) => const ResetPasswordSuccessView(),
        );
      case employeeHome:
        return MaterialPageRoute(builder: (_) => const EmployeeHomeView());
      case employeeRegistroAsistencia:
        return MaterialPageRoute(
          builder: (_) => const RegistroAsistenciaView(),
        );
      case employeeHorarioTrabajo:
        return MaterialPageRoute(builder: (_) => const HorarioTrabajoView());
      case employeeHistorial:
        return MaterialPageRoute(builder: (_) => const HistorialView());
      case employeeAvisos:
        return MaterialPageRoute(builder: (_) => const AvisosView());
      case employeeSettings:
        return MaterialPageRoute(builder: (_) => const SettingsView());
      case employeePersonalInfo:
        return MaterialPageRoute(builder: (_) => const PersonalInfoView());
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminShellView());
      case adminNuevoEmpleado:
        return MaterialPageRoute(builder: (_) => const NuevoEmpleadoView());
      case adminEmpleadosList:
        return MaterialPageRoute(builder: (_) => const EmpleadosListView());
      case adminEmpleadoDetalle:
        return MaterialPageRoute(builder: (_) => const EmpleadoDetalleView());
      case adminHorario:
        return MaterialPageRoute(builder: (_) => const HorarioAdminView());
      case adminAnuncios:
        return MaterialPageRoute(builder: (_) => const AnunciosAdminView());
      case adminNuevoAnuncio:
        return MaterialPageRoute(builder: (_) => const NuevoAnuncioView());
      case adminAparienciaApp:
        return MaterialPageRoute(builder: (_) => const AparienciaAppView());
      case superAdminHome:
        return MaterialPageRoute(builder: (_) => const SuperAdminShellView());
      case superAdminOrganizaciones:
        return MaterialPageRoute(
          builder: (_) => const OrganizacionesListView(),
        );
      case superAdminOrganizacionDetalle:
        return MaterialPageRoute(
          builder: (_) => const OrganizacionDetalleView(),
        );
      case superAdminConfigGlobal:
        return MaterialPageRoute(builder: (_) => const ConfigGlobalView());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
