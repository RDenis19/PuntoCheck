import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/core/utils/validators.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';
import 'package:puntocheck/presentation/widgets/text_field_icon.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _prefilledEmail = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilledEmail) {
      final remembered = context.read<AuthController>().rememberedEmail;
      if (remembered != null) {
        _emailController.text = remembered;
      }
      _prefilledEmail = true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = context.read<AuthController>();
    final result = await controller.login(_emailController.text, _passwordController.text);
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      _showSnack(result.message ?? 'No pudimos iniciar sesión');
    } else {
      context.go('/home');
    }
  }

  Future<void> _loginWithBiometrics() async {
    final controller = context.read<AuthController>();
    final result = await controller.loginWithBiometrics();
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      _showSnack(result.message ?? 'No fue posible usar biometría');
    } else {
      context.go('/home');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('PuntoCheck', style: AppTheme.title),
                const SizedBox(height: 8),
                Text('Control de Asistencia', style: AppTheme.subtitle),
                const SizedBox(height: 48),
                TextFieldIcon(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  label: 'Correo corporativo',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFieldIcon(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  label: 'Contraseña',
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.isLoading ? null : () => context.push('/forgot-email'),
                    child: const Text('¿Olvidaste Contraseña?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Iniciar Sesión',
                  onPressed: controller.isLoading ? null : _submit,
                  isLoading: controller.isLoading,
                ),
                const SizedBox(height: 24),
                _BiometricSection(onTap: controller.isLoading ? null : _loginWithBiometrics),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: controller.isLoading ? null : () => context.push('/register'),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '¿No tienes cuenta? ', style: TextStyle(color: AppTheme.darkTextColor)),
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _BiometricSection extends StatelessWidget {
  const _BiometricSection({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    if (!controller.biometricAvailable) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const Divider(height: 32),
        Text('Autenticación Biométrica', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: controller.biometricEnabled ? onTap : null,
          icon: const Icon(Icons.fingerprint, size: 28),
          label: Text(controller.biometricEnabled ? 'Usar huella / FaceID' : 'Habilita la biometría en Ajustes'),
        ),
      ],
    );
  }
}
