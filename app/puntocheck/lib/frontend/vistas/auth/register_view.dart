import 'package:flutter/material.dart';
import 'package:puntocheck/core/constants/strings.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_text_field.dart';
import 'package:puntocheck/frontend/vistas/auth/widgets/auth_buttons.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
/// Pantalla de registro de nueva cuenta con validacion mock.
/// 
/// TODO(backend): Enviar datos al servicio de Auth para crear usuario.
/// Motivo: Validar email unico, encriptar contrasena, persistir en base de datos,
/// y devolver el usuario autenticado con rol asignado.
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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock: Solo mostrar exito
      _showSuccess(AppStrings.registrationSuccess);

      // Navegar a login despues de un delay
      await Future.delayed(const Duration(seconds: 1));
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const CircleLogoAsset(size: 100),
                const SizedBox(height: 24),
                Text(
                  AppStrings.registerTitle,
                  style: AppTheme.title,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tu perfil',
                  style: AppTheme.subtitle,
                ),
                const SizedBox(height: 32),

                // Full name field
                AuthTextField(
                  hintText: AppStrings.fullName,
                  controller: _nameController,
                  validator: _validateName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),

                // Email field
                AuthTextField(
                  hintText: AppStrings.email,
                  controller: _emailController,
                  validator: _validateEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Phone field
                AuthTextField(
                  hintText: AppStrings.phone,
                  controller: _phoneController,
                  validator: _validatePhone,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                // Password field
                AuthTextField(
                  hintText: AppStrings.password,
                  controller: _passwordController,
                  validator: _validatePassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 14),

                // Confirm password field
                AuthTextField(
                  hintText: AppStrings.confirmPassword,
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Register button
                SizedBox(
                  width: double.infinity,
                  child: AuthButtons.primary(
                    label: AppStrings.registerButton,
                    onPressed: _onRegister,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 16),

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