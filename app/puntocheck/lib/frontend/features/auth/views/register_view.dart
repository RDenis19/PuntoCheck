import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/frontend/features/auth/controllers/auth_controller.dart';
import 'package:puntocheck/frontend/features/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/frontend/features/shared/widgets/primary_button.dart';
import 'package:puntocheck/frontend/features/shared/widgets/text_field_icon.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    Future<void> _onRegister() async {
      final nombreCompleto = _nameController.text.trim();
      final email = _emailController.text.trim();
      final telefono = _phoneController.text.trim();
      final password = _passwordController.text;
      final confirm = _confirmPasswordController.text;

      if (nombreCompleto.isEmpty || email.isEmpty || telefono.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos')), 
        );
        return;
      }
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }
      if (!_accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar términos y condiciones')),
        );
        return;
      }

      final authController = context.read<AuthController>();
      final result = await authController.register(
        nombreCompleto: nombreCompleto,
        email: email,
        telefono: telefono,
        password: password,
        photoPath: null,
      );

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error al registrarse')),
        );
        return;
      }

      final role = authController.currentUser?.role ?? 'employee';
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRouter.adminHome);
        return;
      }
      if (role == 'superadmin') {
        Navigator.pushReplacementNamed(context, AppRouter.superAdminHome);
        return;
      }
      Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // TODO(backend): aquí se integraría la selección de imagen (cámara/galería)
                  // y el upload al storage del backend.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de agregar foto no implementada.'),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primaryRed,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 30),
                      SizedBox(height: 4),
                      Text(
                        'Agregar Foto',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Nombre Completo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFieldIcon(
                controller: _nameController,
                hintText: 'Ingresa su nombre completo',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Correo Electrónico',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFieldIcon(
                controller: _emailController,
                hintText: 'ejemplo@correo.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Número Telefónico',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFieldIcon(
                controller: _phoneController,
                hintText: '+593 985676289',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text(
                'Contraseña',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFieldIcon(
                controller: _passwordController,
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirmar contraseña',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFieldIcon(
                controller: _confirmPasswordController,
                hintText: 'Repita contraseña',
                prefixIcon: Icons.lock_outline,
                obscure: _obscureConfirmPassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (value) => setState(() => _accepted = value ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Términos y Privacidad (mock)')),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          children: [
                            TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'Términos y Condiciones',
                              style: TextStyle(color: Colors.blue),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(color: Colors.blue),
                            ),
                            TextSpan(text: ' de PuntoCheck.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Registrar Empleado',
                onPressed: _onRegister,
              ),
              const SizedBox(height: 16),
              OutlinedDarkButton(
                text: 'Cancelar',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}



