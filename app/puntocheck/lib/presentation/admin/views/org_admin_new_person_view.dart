import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/presentation/admin/widgets/manager_selector.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminNewPersonView extends ConsumerStatefulWidget {
  const OrgAdminNewPersonView({super.key});

  @override
  ConsumerState<OrgAdminNewPersonView> createState() =>
      _OrgAdminNewPersonViewState();
}

class _OrgAdminNewPersonViewState extends ConsumerState<OrgAdminNewPersonView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'Temporal123*');
  final _namesCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  RolUsuario _role = RolUsuario.employee;
  String? _jefeInmediatoId;
  bool _isSaving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _namesCtrl.dispose();
    _lastCtrl.dispose();
    _cedulaCtrl.dispose();
    _telCtrl.dispose();
    _cargoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(Organizaciones org) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final sessionTransition = ref.read(authSessionTransitionProvider.notifier);
    sessionTransition.state = true;
    try {
      final auth = ref.read(authServiceProvider);
      final staff = ref.read(staffServiceProvider);
      final cedula = _cedulaCtrl.text.trim();
      final telefono = _telCtrl.text.trim();
      final cargo = _cargoCtrl.text.trim();
      final metadata = <String, String?>{
        'rol': _role.value,
        'organizacion_id': org.id,
        'nombres': _namesCtrl.text.trim(),
        'apellidos': _lastCtrl.text.trim(),
        'cargo': cargo,
        'telefono': telefono,
        'cedula': cedula,
      }..removeWhere((key, value) => value == null || value.trim().isEmpty);

      await auth.createUserPreservingSession(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        metadata: metadata,
        runWithNewUserSession: (user) async {
          await Future.delayed(const Duration(milliseconds: 300));
          await staff.updateProfile(
            user.id,
            {
              'nombres': _namesCtrl.text.trim(),
              'apellidos': _lastCtrl.text.trim(),
              'rol': _role.value,
              'cedula': cedula.isEmpty ? null : cedula,
              'telefono': telefono.isEmpty ? null : telefono,
              'cargo': cargo.isEmpty ? null : cargo,
              'jefe_inmediato_id': _jefeInmediatoId,
            }..removeWhere((key, value) => value == null),
          );
        },
      );

      ref.invalidate(orgAdminStaffProvider);

      if (!mounted) return;
      showAppSnackBar(context, 'Empleado creado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      showAppSnackBar(context, 'Error: $message', success: false);
    } finally {
      sessionTransition.state = false;
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(orgAdminOrganizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo empleado')),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (org) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear cuenta y perfil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Se crea el usuario en Auth y el perfil en perfiles. Solo roles manager, auditor o empleado.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña temporal',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.neutral600,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 8
                        ? 'Mínimo 8 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _namesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombres',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lastCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cedulaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cédula (opcional)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cargoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RolUsuario>(
                    value: _role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: RolUsuario.employee,
                        child: Text('Empleado'),
                      ),
                      DropdownMenuItem(
                        value: RolUsuario.manager,
                        child: Text('Manager'),
                      ),
                      DropdownMenuItem(
                        value: RolUsuario.auditor,
                        child: Text('Auditor'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _role = v ?? RolUsuario.employee),
                  ),
                  const SizedBox(height: 12),
                  ManagerSelector(
                    selectedManagerId: _jefeInmediatoId,
                    onChanged: (value) =>
                        setState(() => _jefeInmediatoId = value),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(_isSaving ? 'Creando...' : 'Crear empleado'),
                      onPressed: _isSaving ? null : () => _submit(org),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
