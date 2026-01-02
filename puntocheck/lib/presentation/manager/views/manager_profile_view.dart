import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/shared/views/shared_profile_scaffold.dart';
import 'package:puntocheck/presentation/shared/widgets/profile_widgets.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista UNIFICADA para Managers.
/// Usa [SharedProfileScaffold].
class ManagerProfileView extends ConsumerStatefulWidget {
  const ManagerProfileView({super.key});

  @override
  ConsumerState<ManagerProfileView> createState() => _ManagerProfileViewState();
}

class _ManagerProfileViewState extends ConsumerState<ManagerProfileView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isEditing = false;
  
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    _nombresCtrl = TextEditingController();
    _apellidosCtrl = TextEditingController();
    _cargoCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _cargoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile({
    required String userId,
    required String nombres,
    required String apellidos,
    required String cargo,
    required String telefono,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(staffServiceProvider).updateProfile(userId, {
        'nombres': nombres,
        'apellidos': apellidos,
        'cargo': cargo,
        'telefono': telefono,
      });
      ref.invalidate(managerProfileProvider);

      if (!mounted) return;
      setState(() => _isEditing = false);
      _showSuccess('Perfil actualizado exitosamente');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword(String newPassword) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updatePassword(newPassword);
      if (!mounted) return;
      _showSuccess('Contraseña actualizada');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _syncControllers(dynamic perfil) {
    if (_isEditing) return;
    _nombresCtrl.text = perfil.nombres;
    _apellidosCtrl.text = perfil.apellidos;
    _cargoCtrl.text = perfil.cargo ?? '';
    _telefonoCtrl.text = perfil.telefono ?? '';
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(managerProfileProvider);
    final orgAsync = ref.watch(managerOrganizationProvider);
    final user = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error cargando perfil: $e')),
      ),
      data: (perfil) {
        _syncControllers(perfil);

        return SharedProfileScaffold(
          userName: '${perfil.nombres} ${perfil.apellidos}',
          userEmail: user?.email ?? '',
          initials: perfil.nombres.isNotEmpty ? perfil.nombres[0].toUpperCase() : '?',
          isEditing: _isEditing,
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar perfil',
              )
            else
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
              ),
          ],
          children: [
            // 1. Datos Personales
            Form(
              key: _formKey,
              child: ProfileSectionCard(
                title: 'Información Personal',
                icon: Icons.person_outline,
                children: [
                  ProfileTextField(
                    label: 'Nombres',
                    controller: _nombresCtrl,
                    enabled: _isEditing,
                    icon: Icons.badge_outlined,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Apellidos',
                    controller: _apellidosCtrl,
                    enabled: _isEditing,
                    icon: Icons.badge_outlined,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Cargo',
                    controller: _cargoCtrl,
                    enabled: _isEditing,
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Teléfono',
                    controller: _telefonoCtrl,
                    enabled: _isEditing,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neutral700,
                              side: const BorderSide(color: AppColors.neutral300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _updateProfile(
                                      userId: perfil.id,
                                      nombres: _nombresCtrl.text.trim(),
                                      apellidos: _apellidosCtrl.text.trim(),
                                      cargo: _cargoCtrl.text.trim(),
                                      telefono: _telefonoCtrl.text.trim(),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 2. Organización
            ProfileSectionCard(
              title: 'Mi Organización',
              icon: Icons.business_outlined,
              children: [
                orgAsync.when(
                  data: (org) => Column(
                    children: [
                      ProfileInfoChip(
                        label: 'Nombre', 
                        value: org.razonSocial, 
                        icon: Icons.apartment,
                      ),
                      const SizedBox(height: 12),
                      ProfileInfoChip(
                        label: 'RUC', 
                        value: org.ruc, 
                        icon: Icons.numbers,
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e', style: const TextStyle(color: AppColors.errorRed)),
                ),
              ],
            ),

            // 3. Seguridad
            ProfileSectionCard(
              title: 'Seguridad',
              icon: Icons.security_outlined,
              children: [
                ProfileInfoChip(
                  label: 'Correo electrónico',
                  value: user?.email ?? '',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _showPasswordDialog(context),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Cambiar contraseña'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neutral900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: const BorderSide(color: AppColors.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primaryRed),
            SizedBox(width: 12),
            Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v != ctrl.text ? 'No coinciden' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.neutral600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _changePassword(ctrl.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
