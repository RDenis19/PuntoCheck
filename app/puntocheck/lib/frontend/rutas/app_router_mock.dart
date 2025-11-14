import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/vistas/admin/admin_home_view.dart';
import 'package:puntocheck/frontend/vistas/auth/forgot_password_email_view.dart';
import 'package:puntocheck/frontend/vistas/auth/login_view.dart';
import 'package:puntocheck/frontend/vistas/auth/register_view.dart';
import 'package:puntocheck/frontend/vistas/empleado/employee_home_view.dart';
import 'package:puntocheck/frontend/vistas/splash/splash_view.dart';
import 'package:puntocheck/frontend/vistas/auth/forgot_password_code_view.dart';
import 'package:puntocheck/frontend/vistas/auth/reset_password_view.dart';
import 'package:puntocheck/frontend/vistas/auth/reset_password_success_view.dart';
import 'package:puntocheck/frontend/vistas/superadmin/super_admin_home_view.dart';

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
  static const String adminHome = '/admin/home';
  static const String superAdminHome = '/superadmin/home';

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
        return MaterialPageRoute(builder: (_) => const ForgotPasswordEmailView());
      case forgotCode:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordCodeView());
      case resetPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordView());
      case resetPasswordSuccess:
        return MaterialPageRoute(builder: (_) => const ResetPasswordSuccessView());
      case employeeHome:
        return MaterialPageRoute(builder: (_) => const EmployeeHomeView());
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeView());
      case superAdminHome:
        return MaterialPageRoute(builder: (_) => const SuperAdminHomeView());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
