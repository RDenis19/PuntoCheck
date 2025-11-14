import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';
import 'package:puntocheck/frontend/controllers/auth_controller.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

    if (!mounted) return;
    final authController = context.read<AuthController>();
    final email = _emailController.text.trim();

    final result = await authController.sendResetEmail(email);

    if (result.isSuccess) {
      if (!mounted) return;
      _showSuccess(AppStrings.resetCodeSent);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    } else {
      if (!mounted) return;
      _showError(result.message ?? 'Error al enviar enlace de recuperación');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const CircleLogoAsset(size: 120),
                    const SizedBox(height: 32),
                    Text(AppStrings.forgotPasswordTitle, style: AppTheme.title),
                    const SizedBox(height: 8),
                    Text('Ingresa tu correo para recuperar acceso', style: AppTheme.subtitle),
                    const SizedBox(height: 40),
                    AuthTextField(
                      hintText: AppStrings.recoveryEmail,
                      controller: _emailController,
                      validator: _validateEmail,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AuthButtons.primary(
                        label: AppStrings.resetPasswordButton,
                        onPressed: _onRecover,
                        isLoading: authController.isLoading,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthButtons.textButton(
                      label: AppStrings.backToLogin,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
