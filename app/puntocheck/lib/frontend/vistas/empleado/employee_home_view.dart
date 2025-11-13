import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla principal del Empleado.
/// 
/// TODO(backend): Cargar datos del empleado (nombre, ultima asistencia, horario del dia, etc.)
/// Motivo: Necesitamos mostrar informacion personalizada al usuario autenticado.
/// Integrar con endpoints: GET /api/employee/profile, GET /api/employee/attendance/last, etc.
class EmployeeHomeView extends StatelessWidget {
  const EmployeeHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Panel Empleado'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.employeeHome,
              style: AppTheme.title,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Panel de control para empleados. Aqui se mostraran datos de asistencia, horario y mas.',
                textAlign: TextAlign.center,
                style: AppTheme.subtitle,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRouter.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}