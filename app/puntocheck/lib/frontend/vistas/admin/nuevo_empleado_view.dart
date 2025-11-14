import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/widgets/outlined_dark_button.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';
import 'package:puntocheck/frontend/widgets/text_field_icon.dart';

class NuevoEmpleadoView extends StatefulWidget {
  const NuevoEmpleadoView({super.key});

  @override
  State<NuevoEmpleadoView> createState() => _NuevoEmpleadoViewState();
}

class _NuevoEmpleadoViewState extends State<NuevoEmpleadoView> {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isAdmin = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              hintText: 'Correo electrónico',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFieldIcon(
              controller: _telefonoController,
              hintText: 'Número telefónico',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFieldIcon(
              controller: _passwordController,
              hintText: 'Contraseña',
              prefixIcon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 16),
            TextFieldIcon(
              controller: _confirmPasswordController,
              hintText: 'Confirmar contraseña',
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
              text: 'Registrar Empleado',
              onPressed: () {
                // TODO(backend): crear el usuario en Auth y almacenar su perfil con rol.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Empleado registrado (mock).')),
                );
              },
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
