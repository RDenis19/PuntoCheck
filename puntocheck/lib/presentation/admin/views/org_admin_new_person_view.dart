import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/presentation/admin/widgets/branch_selector.dart';
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
  String? _sucursalId;
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
    if (_sucursalId == null || _sucursalId!.isEmpty) {
      showAppSnackBar(context, 'Selecciona una sucursal', success: false);
      return;
    }

    // Validación extra: la sucursal debe existir dentro de la organización.
    final branches = await ref.read(orgAdminBranchesProvider.future);
    if (!mounted) return;
    final isBranchValid = branches.any((b) => b.id == _sucursalId);
    if (!isBranchValid) {
      showAppSnackBar(
        context,
        'Sucursal inválida para esta organización',
        success: false,
      );
      return;
    }

    if (_role == RolUsuario.superAdmin || _role == RolUsuario.orgAdmin) {
      showAppSnackBar(context, 'Rol no permitido', success: false);
      return;
    }
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
        // Metadata opcional para auditoría / triggers; el perfil se creará explícitamente.
        'rol': _role.value,
        'organizacion_id': org.id,
        'nombres': _namesCtrl.text.trim(),
        'apellidos': _lastCtrl.text.trim(),
        'cargo': cargo,
        'telefono': telefono,
        'cedula': cedula,
        'sucursal_id': _sucursalId,
      }..removeWhere((key, value) => value == null || value.trim().isEmpty);

      final createdUser = await auth.createUserPreservingSession(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        metadata: metadata,
      );

      // Crear/actualizar el perfil en la BD bajo la sesión del org_admin (RLS).
      // Si existe trigger `handle_new_user`, createOrgProfile hará update en caso de duplicado.
      await staff.createOrgProfile(
        userId: createdUser.id,
        orgId: org.id,
        nombres: _namesCtrl.text.trim(),
        apellidos: _lastCtrl.text.trim(),
        rol: _role,
        cedula: cedula.isEmpty ? null : cedula,
        telefono: telefono.isEmpty ? null : telefono,
        cargo: cargo.isEmpty ? null : cargo,
        sucursalId: _sucursalId,
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
                      prefixIcon: Icon(Icons.email_rounded),
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
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                            prefixIcon: Icon(Icons.person_outline_rounded),
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
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cargoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RolUsuario>(
                    key: ValueKey(_role),
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.security_rounded),
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
                  BranchSelector(
                    label: 'Sucursal',
                    selectedBranchId: _sucursalId,
                    showAllOption: false,
                    onChanged: (value) => setState(() => _sucursalId = value),
                  ),
                  const SizedBox(height: 20),
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
                          : const Icon(Icons.person_add_rounded),
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
