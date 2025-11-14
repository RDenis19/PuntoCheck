import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/frontend/controllers/auth_controller.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';
import 'package:puntocheck/frontend/widgets/text_field_icon.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa email y contraseña')),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final result = await authController.login(email, password);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Error al iniciar sesión')),
      );
      return;
    }

    final role = authController.currentUser?.role ?? 'employee';
    if (!mounted) return;
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, AppRouter.adminHome);
      return;
    }
    if (role == 'superadmin') {
      Navigator.pushReplacementNamed(context, AppRouter.superAdminHome);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const CircleLogoAsset(),
              const SizedBox(height: 20),
              const Text(
                'PuntoCheck',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control de Asistencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 40),
              TextFieldIcon(
                controller: _emailController,
                hintText: 'Correo Electrónico',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFieldIcon(
                controller: _passwordController,
                hintText: 'Contraseña',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.forgotEmail);
                  },
                  child: Text(
                    '¿Olvidaste Contraseña?',
                    style: TextStyle(color: Colors.indigo.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<AuthController>(
                builder: (context, authController, _) => PrimaryButton(
                  text: authController.isLoading ? 'Ingresando...' : 'Iniciar Sesión',
                  enabled: !authController.isLoading,
                  onPressed: _onLogin,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'o',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // TODO(backend): aquí se integraría el servicio de biometría (Face ID / Huella).
                  // Razón: permitir login rápido sin contraseña.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de biometría no implementada.'),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed.withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fingerprint,
                        color: AppColors.primaryRed,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Usar Autentificación Biométrica'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Nuevo usuario? ',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.register);
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
