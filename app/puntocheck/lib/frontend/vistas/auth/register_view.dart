import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';
import 'package:puntocheck/frontend/controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyFullName;
    }
    return null;
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyPhone;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyPassword;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emptyConfirmPassword;
    }
    if (value != _passwordController.text) {
      return AppStrings.passwordMismatch;
    }
    return null;
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    final authController = context.read<AuthController>();
    final nombreCompleto = _nameController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _phoneController.text.trim();
    final password = _passwordController.text;

    final result = await authController.register(
      nombreCompleto: nombreCompleto,
      email: email,
      telefono: telefono,
      password: password,
      photoPath: null,
      context: context,
    );

    if (!result.isSuccess) {
      if (!mounted) return;
      _showError(result.message ?? 'Error al registrarse');
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const CircleLogoAsset(size: 100),
                    const SizedBox(height: 24),
                    Text(AppStrings.registerTitle, style: AppTheme.title),
                    const SizedBox(height: 8),
                    Text('Completa tu perfil', style: AppTheme.subtitle),
                    const SizedBox(height: 32),
                    AuthTextField(
                      hintText: AppStrings.fullName,
                      controller: _nameController,
                      validator: _validateName,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hintText: AppStrings.email,
                      controller: _emailController,
                      validator: _validateEmail,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hintText: AppStrings.phone,
                      controller: _phoneController,
                      validator: _validatePhone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hintText: AppStrings.password,
                      controller: _passwordController,
                      validator: _validatePassword,
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      hintText: AppStrings.confirmPassword,
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AuthButtons.primary(
                        label: AppStrings.registerButton,
                        onPressed: _onRegister,
                        isLoading: authController.isLoading,
                      ),
                    ),
                    const SizedBox(height: 16),
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
