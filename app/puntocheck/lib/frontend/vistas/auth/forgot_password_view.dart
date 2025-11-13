import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla de recuperacion de contrasena con flujo mock.
/// 
/// TODO(backend): Integrar con servicio de email para enviar codigo de recuperacion.
/// Motivo: Validar que el email existe, generar codigo temporal, enviar por email,
/// y permitir que el usuario establezca nueva contrasena.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyEmail;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  void _onRecover() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock: Mostrar exito
      _showSuccess(AppStrings.resetCodeSent);

      // Navegar a login despues de un delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  AppStrings.forgotPasswordTitle,
                  style: AppTheme.title,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu correo para recuperar acceso',
                  style: AppTheme.subtitle,
                ),
                const SizedBox(height: 40),

                // Email field
                AuthTextField(
                  hintText: AppStrings.recoveryEmail,
                  controller: _emailController,
                  validator: _validateEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // Send code button
                SizedBox(
                  width: double.infinity,
                  child: AuthButtons.primary(
                    label: AppStrings.resetPasswordButton,
                    onPressed: _onRecover,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 24),

                // Back to login link
                AuthButtons.textButton(
                  label: AppStrings.backToLogin,
                  onPressed: () {
                    Navigator.pop(context);
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