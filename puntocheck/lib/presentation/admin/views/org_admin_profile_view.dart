import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/presentation/shared/views/shared_profile_scaffold.dart';
import 'package:puntocheck/presentation/shared/widgets/profile_widgets.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista profesional UNIFICADA para Admin de Organización.
/// Usa [SharedProfileScaffold] para mantener consistencia con otros roles.
class OrgAdminProfileView extends ConsumerStatefulWidget {
  const OrgAdminProfileView({super.key});

  @override
  ConsumerState<OrgAdminProfileView> createState() =>
      _OrgAdminProfileViewState();
}

class _OrgAdminProfileViewState extends ConsumerState<OrgAdminProfileView> {
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

  // --- LÓGICA DE ACTUALIZACIÓN ---

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
      ref.invalidate(profileProvider);

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

  void _syncControllers(Perfiles perfil) {
    if (_isEditing) return;
    _nombresCtrl.text = perfil.nombres;
    _apellidosCtrl.text = perfil.apellidos;
    _cargoCtrl.text = perfil.cargo ?? '';
    _telefonoCtrl.text = perfil.telefono ?? '';
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Text(msg)
        ]),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(msg))
        ]),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final orgAsync = ref.watch(orgAdminOrganizationProvider);
    final user = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error cargando perfil: $e')),
      ),
      data: (perfil) {
        if (perfil == null) return const Scaffold(body: Center(child: Text('Sin perfil')));

        _syncControllers(perfil);

        return SharedProfileScaffold(
          userName: '${perfil.nombres} ${perfil.apellidos}',
          userEmail: user?.email ?? '',
          initials: perfil.nombres.isNotEmpty ? perfil.nombres[0].toUpperCase() : '?',
          isEditing: _isEditing,
          // Acciones de la AppBar (Botón Editar)
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Editar perfil',
              )
            else
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancelar',
              ),
          ],
          children: [
            // 1. Datos Personales
            Form(
              key: _formKey,
              child: ProfileSectionCard(
                title: 'Información Personal',
                icon: Icons.person_outline_rounded,
                children: [
                  ProfileTextField(
                    label: 'Nombres',
                    controller: _nombresCtrl,
                    enabled: _isEditing,
                    icon: Icons.badge_rounded,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Apellidos',
                    controller: _apellidosCtrl,
                    enabled: _isEditing,
                    icon: Icons.badge_rounded,
                    validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Cargo',
                    controller: _cargoCtrl,
                    enabled: _isEditing,
                    icon: Icons.work_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: 'Teléfono',
                    controller: _telefonoCtrl,
                    enabled: _isEditing,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // Botones de Guardar (Si está editando)
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

            // 2. Organización (Solo lectura)
            ProfileSectionCard(
              title: 'Mi Organización',
              icon: Icons.business_rounded,
              children: [
                orgAsync.when(
                  data: (org) => Column(
                    children: [
                      ProfileInfoChip(
                        label: 'Nombre', 
                        value: org.razonSocial, 
                        icon: Icons.apartment_rounded,
                      ),
                      const SizedBox(height: 12),
                      ProfileInfoChip(
                        label: 'RUC', 
                        value: org.ruc, 
                        icon: Icons.numbers_rounded,
                      ),
                      const SizedBox(height: 12),
                      ProfileInfoChip(
                        label: 'Suscripción', 
                        value: org.estadoSuscripcion?.value ?? 'N/D', 
                        icon: Icons.verified_rounded,
                        valueColor: AppColors.successGreen,
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
              icon: Icons.security_rounded,
              children: [
                ProfileInfoChip(
                  label: 'Correo electrónico',
                  value: user?.email ?? '',
                  icon: Icons.email_rounded,
                ),
                const SizedBox(height: 16),
                
                // Botón Cambiar Contraseña
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _showPasswordDialog(context),
                  icon: const Icon(Icons.lock_reset_rounded),
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
                
                // Botón Cerrar Sesión
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
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
            Icon(Icons.lock_reset_rounded, color: AppColors.primaryRed),
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
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
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
