import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla principal del Super Admin.
/// 
/// TODO(backend): Gestionar multi-tenant y configuracion global.
/// Motivo: Super admins necesitan acceso a multiples organizaciones, politicas globales,
/// branding, usuarios, etc.
/// Integrar con endpoints: GET /api/superadmin/organizations, GET /api/superadmin/settings, etc.
class SuperAdminHomeView extends StatelessWidget {
  const SuperAdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Panel Super Admin'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.superAdminHome,
              style: AppTheme.title,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Panel de super administracion. Aqui se gestionan organizaciones, politicas globales y usuarios.',
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