import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/presentation/admin/widgets/branch_selector.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista para editar información de un empleado existente
/// Permite modificar: nombres, apellidos, rol, cargo, teléfono, cédula, jefe inmediato, estado
class OrgAdminEditPersonView extends ConsumerStatefulWidget {
  final String userId;

  const OrgAdminEditPersonView({super.key, required this.userId});

  @override
  ConsumerState<OrgAdminEditPersonView> createState() =>
      _OrgAdminEditPersonViewState();
}

class _OrgAdminEditPersonViewState
    extends ConsumerState<OrgAdminEditPersonView> {
  final _formKey = GlobalKey<FormState>();
  final _namesCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();

  RolUsuario _role = RolUsuario.employee;
  String? _sucursalId;
  bool _activo = true;
  bool _isSaving = false;
  Perfiles? _perfil;

  @override
  void dispose() {
    _namesCtrl.dispose();
    _lastCtrl.dispose();
    _cedulaCtrl.dispose();
    _telCtrl.dispose();
    _cargoCtrl.dispose();
    super.dispose();
  }

  void _loadProfile(Perfiles perfil) {
    if (_perfil != null) return; // Ya cargado

    _perfil = perfil;
    _namesCtrl.text = perfil.nombres;
    _lastCtrl.text = perfil.apellidos;
    _cedulaCtrl.text = perfil.cedula ?? '';
    _telCtrl.text = perfil.telefono ?? '';
    _cargoCtrl.text = perfil.cargo ?? '';
    _role = perfil.rol ?? RolUsuario.employee;
    _sucursalId = perfil.sucursalId;
    _activo = perfil.activo ?? true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_role == RolUsuario.superAdmin || _role == RolUsuario.orgAdmin) {
        throw Exception('Rol no permitido');
      }

      if (_sucursalId != null && _sucursalId!.isNotEmpty) {
        final branches = await ref.read(orgAdminBranchesProvider.future);
        final isBranchValid = branches.any((b) => b.id == _sucursalId);
        if (!isBranchValid) {
          throw Exception('Sucursal inválida para esta organización');
        }
      }

      final staff = ref.read(staffServiceProvider);
      final cedula = _cedulaCtrl.text.trim();
      final telefono = _telCtrl.text.trim();
      final cargo = _cargoCtrl.text.trim();

      await staff.updateProfile(
        widget.userId,
        {
          'nombres': _namesCtrl.text.trim(),
          'apellidos': _lastCtrl.text.trim(),
          'rol': _role.value,
          'cedula': cedula.isEmpty ? null : cedula,
          'telefono': telefono.isEmpty ? null : telefono,
          'cargo': cargo.isEmpty ? null : cargo,
          'sucursal_id': _sucursalId,
          'activo': _activo,
        }..removeWhere((key, value) => value == null),
      );

      // Invalidar providers afectados
      ref.invalidate(orgAdminStaffProvider);
      ref.invalidate(orgAdminPersonProvider(widget.userId));

      if (!mounted) return;
      showAppSnackBar(context, 'Empleado actualizado correctamente');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      showAppSnackBar(context, 'Error: $message', success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(orgAdminPersonProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Editar empleado'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryRed,
        iconTheme: const IconThemeData(color: AppColors.primaryRed),
        elevation: 0,
      ),
      body: perfilAsync.when(
        data: (perfil) {
          _loadProfile(perfil);
          return _buildForm(context, perfil);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando perfil: $e')),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Perfiles perfil) {
    // Verificar si está editando su propio perfil
    final currentUserAsync = ref.watch(profileProvider);
    final currentUserId = currentUserAsync.value?.id;
    final isOwnProfile = currentUserId == widget.userId;

    // Lista de roles permitidos para edición
    final rolesPermitidos = <DropdownMenuItem<RolUsuario>>[
      const DropdownMenuItem(
        value: RolUsuario.employee,
        child: Text('Empleado'),
      ),
      const DropdownMenuItem(value: RolUsuario.manager, child: Text('Manager')),
      const DropdownMenuItem(value: RolUsuario.auditor, child: Text('Auditor')),
    ];

    // Si el rol actual no está en la lista (ej. org_admin / super_admin), agregarlo para evitar crash.
    final needsSpecialRole =
        _role == RolUsuario.orgAdmin || _role == RolUsuario.superAdmin;
    final alreadyIncluded = rolesPermitidos.any((item) => item.value == _role);
    if (needsSpecialRole && !alreadyIncluded) {
      rolesPermitidos.add(
        DropdownMenuItem(
          value: _role,
          child: Text(
            _role == RolUsuario.orgAdmin
                ? 'Administrador'
                : 'Super Administrador',
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de información básica
          _SectionCard(
            title: 'Información Básica',
            children: [
              TextFormField(
                controller: _namesCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombres *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastCtrl,
                decoration: InputDecoration(
                  labelText: 'Apellidos *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cedulaCtrl,
                decoration: InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card de contacto
          _SectionCard(
            title: 'Contacto',
            children: [
              TextFormField(
                controller: _telCtrl,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral600,
                            ),
                          ),
                          Text(
                            perfil.email ?? perfil.correo ?? 'Sin email',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'El email no se puede modificar desde aquí',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card de información laboral
          _SectionCard(
            title: 'Información Laboral',
            children: [
              DropdownButtonFormField<RolUsuario>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Rol *',
                  prefixIcon: const Icon(Icons.security_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: isOwnProfile
                      ? 'No puedes cambiar tu propio rol'
                      : null,
                  helperStyle: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                items: rolesPermitidos,
                onChanged: isOwnProfile
                    ? null // Deshabilitar si edita su propio perfil
                    : (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cargoCtrl,
                decoration: InputDecoration(
                  labelText: 'Cargo',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              BranchSelector(
                label: 'Sucursal',
                selectedBranchId: _sucursalId,
                showAllOption: false,
                onChanged: (value) => setState(() => _sucursalId = value),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card de estado
          _SectionCard(
            title: 'Estado',
            children: [
              SwitchListTile(
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
                title: const Text('Empleado activo'),
                subtitle: Text(
                  _activo
                      ? 'El empleado puede iniciar sesión y marcar asistencia'
                      : 'El empleado no podrá iniciar sesión',
                  style: const TextStyle(fontSize: 12),
                ),
                activeColor: AppColors.primaryRed,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón de guardar
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widget de sección con card
// ============================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
