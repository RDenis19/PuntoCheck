import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla principal del Administrador.
/// 
/// TODO(backend): Cargar KPIs y datos del panel de administracion.
/// Motivo: Mostrar metricas importantes (empleados activos, asistencia del dia, etc.)
/// Integrar con endpoints: GET /api/admin/dashboard, GET /api/admin/employees, etc.
/// Considerar tambien: rutas a sub-secciones (Reportes, Horarios, Anuncios, etc.)
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.adminHome,
              style: AppTheme.title,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Panel de administracion. Aqui se mostraran reportes, empleados, horarios y anuncios.',
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