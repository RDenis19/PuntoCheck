import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/utils/validators.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';
import 'package:puntocheck/presentation/widgets/text_field_icon.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = context.read<AuthController>();
    final result = await controller.updatePassword(_passwordController.text);
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'No se pudo actualizar la contraseña')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada para la sesión actual')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final canUpdate = controller.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'En producción, Firebase envía un enlace seguro para definir tu nueva contraseña. '
                  'Esta pantalla solo ilustra el paso final cuando la app detecta una sesión activa.',
                ),
                if (!canUpdate) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Para completar el proceso, abre el link del correo de Firebase. '
                    'Necesitamos una sesión activa para poder ejecutar updatePassword.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 24),
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
                const SizedBox(height: 16),
                TextFieldIcon(
                  controller: _confirmController,
                  icon: Icons.lock_outline,
                  label: 'Confirmar contraseña',
                  obscureText: _obscureConfirm,
                  validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Actualizar contraseña',
                  onPressed: (!canUpdate || controller.isLoading) ? null : _update,
                  isLoading: controller.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
