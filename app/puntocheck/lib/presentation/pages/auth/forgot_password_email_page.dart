import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/utils/validators.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';
import 'package:puntocheck/presentation/widgets/text_field_icon.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() => _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = context.read<AuthController>();
    final result = await controller.sendResetEmail(_emailController.text);
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'No se pudo enviar el correo')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un enlace/código a tu correo')), // Firebase manda link real
      );
      if (mounted) {
        context.push('/forgot-code');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa tu correo y te enviaremos un enlace con instrucciones oficiales de Firebase.',
                ),
                const SizedBox(height: 24),
                TextFieldIcon(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  label: 'Correo corporativo',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Te enviamos un código',
                  onPressed: controller.isLoading ? null : _sendCode,
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
