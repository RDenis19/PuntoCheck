import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/core/utils/validators.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';
import 'package:puntocheck/presentation/widgets/text_field_icon.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  String? _photoPath;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _photoPath = 'foto_${DateTime.now().millisecondsSinceEpoch}.png';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto seleccionada (simulación)')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos')),
      );
      return;
    }
    final controller = context.read<AuthController>();
    final result = await controller.register(
      nombreCompleto: _nameController.text,
      email: _emailController.text,
      telefono: _phoneController.text,
      password: _passwordController.text,
      photoPath: _photoPath,
    );
    if (!mounted) {
      return;
    }
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'No pudimos registrar la cuenta')),
      );
    } else {
      context.go('/home');
    }
  }
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Empleado'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoPicker(path: _photoPath, onTap: controller.isLoading ? null : _pickPhoto),
                const SizedBox(height: 24),
                TextFieldIcon(
                  controller: _nameController,
                  icon: Icons.person_outline,
                  label: 'Nombre completo',
                  validator: Validators.requiredField,
                ),
                const SizedBox(height: 16),
                TextFieldIcon(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  label: 'Correo corporativo',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFieldIcon(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
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
                const SizedBox(height: 16),
                TextFieldIcon(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  label: 'Confirmar contraseña',
                  obscureText: _obscureConfirm,
                  validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: controller.isLoading ? null : (value) => setState(() => _termsAccepted = value ?? false),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'Acepto Términos y Condiciones y Política de Privacidad',
                        style: TextStyle(color: AppTheme.darkTextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Registrar Empleado',
                  onPressed: controller.isLoading ? null : _submit,
                  isLoading: controller.isLoading,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.isLoading ? null : () => context.pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: path != null ? NetworkImage('https://picsum.photos/seed/${path.hashCode}/200') : null,
            child: path == null
                ? const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.photo_camera_back_outlined),
            label: Text(path == null ? 'Agregar Foto' : 'Cambiar Foto'),
          ),
        ],
      ),
    );
  }
}
