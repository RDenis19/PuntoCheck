import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/rutas/app_router_mock.dart' as mock;

/// Encapsula el router principal. Por ahora delega al mock.
abstract final class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  static const forgotEmail = '/forgot/email';
  static const forgotCode = '/forgot/code';
  static const resetPassword = '/forgot/reset';
  static const resetPasswordSuccess = '/forgot/success';

  // Homes por rol (si ya existen)
  static const employeeHome = '/employee/home';
  static const adminHome = '/admin/home';
  static const superAdminHome = '/superadmin/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) => mock.AppRouterMock.onGenerateRoute(settings);
}
