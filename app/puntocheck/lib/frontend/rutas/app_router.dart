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
  static const employeeRegistroAsistencia = '/employee/registro-asistencia';
  static const employeeHorarioTrabajo = '/employee/horario-trabajo';
  static const employeeHistorial = '/employee/historial';
  static const employeeAvisos = '/employee/avisos';
  static const employeeSettings = '/employee/settings';
  static const employeePersonalInfo = '/employee/personal-info';
  static const adminHome = '/admin/home';
  static const adminNuevoEmpleado = '/admin/nuevo-empleado';
  static const adminEmpleadosList = '/admin/empleados';
  static const adminEmpleadoDetalle = '/admin/empleado-detalle';
  static const adminHorario = '/admin/horario';
  static const adminAnuncios = '/admin/anuncios';
  static const adminNuevoAnuncio = '/admin/anuncios/nuevo';
  static const adminAparienciaApp = '/admin/apariencia-app';
  static const superAdminHome = '/superadmin/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) =>
      mock.AppRouterMock.onGenerateRoute(settings);
}
