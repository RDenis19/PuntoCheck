import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/roles.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla de inicio de sesión con autenticación mock.
/// 
/// TODO(backend): Reemplazar la lógica de validación local con llamadas a
/// un servicio de autenticación real (Firebase Auth, OAuth, API REST, etc.)
/// Motivo: Necesitamos validar credenciales en el servidor, manejar 2FA,
/// y devolver un token de sesión seguro para mantener la autenticación.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el email en formato.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyEmail;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Valida que la contrasena no este vacia.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyPassword;
    }
    return null;
  }

  /// Autentica usando credenciales mock (SOLO FRONTEND).
  /// TODO(backend): Aquí se llamaría al endpoint de autenticación.
  /// Motivo: Validar credenciales en el servidor, generar JWT/sesión,
  /// y devolver información del usuario y rol.
  void _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Mock duro (SOLO FRONTEND)
      if (!kMockUsers.containsKey(email)) {
        _showError(AppStrings.userNotFound);
        return;
      }

      final userData = kMockUsers[email]!;
      if (userData['password'] != password) {
        _showError(AppStrings.invalidPassword);
        return;
      }

      final role = userData['role'] as String;

      // Navega según el rol
      if (!mounted) return;
      switch (role) {
        case AppRoles.employee:
          Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
        case AppRoles.admin:
          Navigator.pushReplacementNamed(context, AppRouter.adminHome);
        case AppRoles.superadmin:
          Navigator.pushReplacementNamed(context, AppRouter.superAdminHome);
        default:
          _showError('Rol desconocido');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Muestra un mensaje de error en un SnackBar.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra un mensaje de éxito en un SnackBar.
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const CircleLogoAsset(size: 120),
                const SizedBox(height: 32),
                Text(
                  AppStrings.loginTitle,
                  style: AppTheme.title,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tus credenciales',
                  style: AppTheme.subtitle,
                ),
                const SizedBox(height: 40),

                // Email field
                AuthTextField(
                  hintText: AppStrings.email,
                  controller: _emailController,
                  validator: _validateEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password field
                AuthTextField(
                  hintText: AppStrings.password,
                  controller: _passwordController,
                  validator: _validatePassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: AuthButtons.primary(
                    label: AppStrings.loginButton,
                    onPressed: _onLogin,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 24),

                // Forgot password link
                AuthButtons.textButton(
                  label: AppStrings.forgotPasswordLink,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.forgot);
                  },
                ),
                const SizedBox(height: 16),

                // Register link
                AuthButtons.textButton(
                  label: AppStrings.registerLink,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.register);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}