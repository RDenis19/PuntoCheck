import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';
import 'package:puntocheck/frontend/controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyPassword;
    }
    return null;
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    final authController = context.read<AuthController>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await authController.login(email, password, context: context);
    if (!result.isSuccess) {
      if (!mounted) return;
      _showError(result.message ?? 'Error al iniciar sesión');
    }
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
                    Text(AppStrings.loginTitle, style: AppTheme.title),
                    const SizedBox(height: 8),
                    Text('Ingresa tus credenciales', style: AppTheme.subtitle),
                    const SizedBox(height: 40),
                    AuthTextField(
                      hintText: AppStrings.email,
                      controller: _emailController,
                      validator: _validateEmail,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      hintText: AppStrings.password,
                      controller: _passwordController,
                      validator: _validatePassword,
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AuthButtons.primary(
                        label: AppStrings.loginButton,
                        onPressed: _onLogin,
                        isLoading: authController.isLoading,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthButtons.textButton(
                      label: AppStrings.forgotPasswordLink,
                      onPressed: () => Navigator.pushNamed(context, AppRouter.forgot),
                    ),
                    const SizedBox(height: 16),
                    AuthButtons.textButton(
                      label: AppStrings.registerLink,
                      onPressed: () => Navigator.pushNamed(context, AppRouter.register),
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
