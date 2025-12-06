import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/shared/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Formulario para crear un admin de organización.
class SuperAdminCreateAdminView extends ConsumerStatefulWidget {
  const SuperAdminCreateAdminView({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<SuperAdminCreateAdminView> createState() =>
      _SuperAdminCreateAdminViewState();
}

class _SuperAdminCreateAdminViewState
    extends ConsumerState<SuperAdminCreateAdminView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'Temporal123*');
  final _namesCtrl = TextEditingController();
  final _lastNamesCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _namesCtrl.dispose();
    _lastNamesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final auth = ref.read(authServiceProvider);

      final user = await auth.createUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        metadata: {
          'rol': RolUsuario.orgAdmin.value,
          'organizacion_id': widget.orgId,
          'nombres': _namesCtrl.text.trim(),
          'apellidos': _lastNamesCtrl.text.trim(),
        },
      );

      showAppSnack(context, 'Admin creado con éxito');
      // Refresca equipo/org para que aparezca de inmediato.
      ref
        ..invalidate(organizationStaffProvider(widget.orgId))
        ..invalidate(superAdminDashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      showAppSnack(context, 'Error creando admin: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear admin'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _Field(
                label: 'Correo',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa correo' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Contraseña temporal',
                controller: _passCtrl,
                obscure: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.neutral600,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Nombres',
                controller: _namesCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa nombres' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Apellidos',
                controller: _lastNamesCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa apellidos' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _submit,
                child: Text(_isSaving ? 'Guardando...' : 'Crear admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryRed),
            ),
          ),
        ),
      ],
    );
  }
}
