import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/frontend/controllers/auth_controller.dart';
import 'package:puntocheck/frontend/widgets/circle_logo_asset.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';
import 'package:puntocheck/frontend/widgets/text_field_icon.dart';

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
      return 'Correo inválido';
    }
    return null;
  }

  void _onRecover() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final authController = context.read<AuthController>();
    final result = await authController.sendResetEmail(email);
    if (result.isSuccess) {
      _showSuccess('Código de recuperación enviado');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRouter.forgotCode);
    } else {
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
                const Text('Olvidaste tu Contraseña', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Por favor ingresa tu correo para recuperar tu contraseña', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),

                // Email field
                TextFieldIcon(
                  controller: _emailController,
                  hintText: 'Ingresa tu correo',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 24),

                // Send code button
                PrimaryButton(
                  text: 'Te enviamos un código',
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    // TODO(backend): aquí se debería disparar el envío de un código al correo.
                    // Razón: verificar que el usuario controla ese correo antes de cambiar la contraseña.
                    _onRecover();
                  },
                ),
                const SizedBox(height: 24),

                // Back to login link
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}