import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/rutas/app_router_mock.dart' as mock;

/// Encapsula el router principal. Por ahora delega al mock.
abstract final class AppRouter {
  static const String splash = mock.AppRouterMock.splash;
  static const String login = mock.AppRouterMock.login;
  static const String register = mock.AppRouterMock.register;
  static const String forgot = mock.AppRouterMock.forgotPassword;

  static const String employeeHome = mock.AppRouterMock.employeeHome;
  static const String adminHome = mock.AppRouterMock.adminHome;
  static const String superAdminHome = mock.AppRouterMock.superAdminHome;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) => mock.AppRouterMock.onGenerateRoute(settings);
}
