import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

class NuevoEmpleadoView extends ConsumerStatefulWidget {
  const NuevoEmpleadoView({super.key});

  @override
  ConsumerState<NuevoEmpleadoView> createState() => _NuevoEmpleadoViewState();
}

class _NuevoEmpleadoViewState extends ConsumerState<NuevoEmpleadoView> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = _generateTempPassword();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerEmployee() async {
    final name = _nombreController.text.trim();
    final email = _correoController.text.trim();
    final phone = _telefonoController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      _showMessage('Correo y contrasena temporal son obligatorios');
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = ref.read(organizationControllerProvider.notifier);
      await controller.createEmployee(
        email: email,
        password: pass,
        fullName: name.isEmpty ? null : name,
        phone: phone.isEmpty ? null : phone,
      );

      final state = ref.read(organizationControllerProvider);
      if (state.hasError) {
        _showMessage(state.error.toString());
      } else {
        _showMessage('Empleado creado exitosamente');
        if (mounted) {
          context.go(AppRoutes.adminEmpleadosList);
        }
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _generateTempPassword() {
    const chars = 'AaBbCcDdEeFfGgHh0123456789@#\$%&*?';
    return List.generate(
      10,
      (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo empleado'),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informacion Personal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFieldIcon(
                    controller: _nombreController,
                    hintText: 'Nombre completo',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  TextFieldIcon(
                    controller: _correoController,
                    hintText: 'Correo electronico',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFieldIcon(
                    controller: _telefonoController,
                    hintText: 'Numero telefonico',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFieldIcon(
                    controller: _passwordController,
                    hintText: 'Contrasena temporal',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    enabled: true,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.black.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tipo de usuario',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se creara con rol de empleado (sin permisos de admin).',
              style: TextStyle(
                color: AppColors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: _saving ? 'Registrando...' : 'Registrar Empleado',
              enabled: !_saving,
              onPressed: _registerEmployee,
            ),
            const SizedBox(height: 12),
            OutlinedDarkButton(
              text: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

