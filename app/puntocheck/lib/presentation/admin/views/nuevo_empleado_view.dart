import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
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
  final _confirmPasswordController = TextEditingController();
  bool _isAdmin = false;
  bool _saving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerEmployee() async {
    // TODO: Conectar con servicio real de creación cuando esté disponible
    final name = _nombreController.text.trim();
    final email = _correoController.text.trim();
    final phone = _telefonoController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showMessage('Completa los campos requeridos');
      return;
    }
    if (pass != confirm) {
      _showMessage('Las contrasenas no coinciden');
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizationId;

      await ref.read(authControllerProvider.notifier).signUp(
        email: email,
        password: pass,
        fullName: name,
        organizationId: orgId,
      );

      final state = ref.read(authControllerProvider);
      if (state.hasError) {
        _showMessage(state.error.toString());
      } else {
        _showMessage('Empleado registrado');
        Navigator.pop(context);
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
              hintText: 'Contrasena',
              prefixIcon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 16),
            TextFieldIcon(
              controller: _confirmPasswordController,
              hintText: 'Confirmar contrasena',
              prefixIcon: Icons.lock_outline,
              obscure: true,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoleButton(
                    label: 'Empleado',
                    selected: !_isAdmin,
                    onTap: () => setState(() => _isAdmin = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleButton(
                    label: 'Admin',
                    selected: _isAdmin,
                    onTap: () => setState(() => _isAdmin = true),
                  ),
                ),
              ],
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

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primaryRed
                : AppColors.black.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : AppColors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

