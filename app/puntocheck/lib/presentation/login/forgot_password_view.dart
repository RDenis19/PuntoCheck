import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/shared/widgets/circle_logo_asset.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu correo';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Correo invalido';
    }
    return null;
  }

  Future<void> _onRecover() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    await ref.read(authControllerProvider.notifier).resetPassword(email);
    final state = ref.read(authControllerProvider);

    if (state.hasError) {
      _showError(state.error?.toString() ?? 'Error al enviar enlace');
      return;
    }

    _showSuccess('Enviamos un codigo a tu correo');
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    context.push(AppRoutes.forgotCode);
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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const CircleLogoAsset(radius: 60),
                const SizedBox(height: 32),
                const Text('Olvidaste tu Contrasena', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Ingresa tu correo para recuperar tu contrasena', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),
                TextFieldIcon(
                  controller: _emailController,
                  hintText: 'Ingresa tu correo',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: isLoading ? 'Enviando...' : 'Te enviamos un codigo',
                  onPressed: _onRecover,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver al inicio de sesion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
