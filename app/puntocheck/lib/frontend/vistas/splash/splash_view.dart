import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';

/// Pantalla de bienvenida (Splash).
/// Muestra el logo de la aplicación durante 2-3 segundos y luego navega a Login.
///
/// TODO(backend): Aquí se podría verificar si existe una sesión persistida (token, etc.)
/// para saltar el login y navegar directamente a la vista del rol correspondiente.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleLogoAsset(size: 150),
            const SizedBox(height: 32),
            Text(
              'PuntoCheck',
              style: AppTheme.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Control de Asistencia',
              style: AppTheme.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}