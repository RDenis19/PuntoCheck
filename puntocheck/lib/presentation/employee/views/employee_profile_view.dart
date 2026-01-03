import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puntocheck/presentation/employee/views/employee_compliance_alerts_view.dart';
import 'package:puntocheck/presentation/shared/views/shared_profile_scaffold.dart';
import 'package:puntocheck/presentation/shared/widgets/profile_widgets.dart';
import 'package:puntocheck/providers/auth_providers.dart';
import 'package:puntocheck/providers/core_providers.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vista UNIFICADA para Empleados.
/// Usa [SharedProfileScaffold] pero inyecta tarjetas específicas de Empleado (Alertas, datos limitados).
class EmployeeProfileView extends ConsumerStatefulWidget {
  const EmployeeProfileView({super.key});

  @override
  ConsumerState<EmployeeProfileView> createState() => _EmployeeProfileViewState();
}

class _EmployeeProfileViewState extends ConsumerState<EmployeeProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();

  bool _isEditing = false;
  bool _isSaving = false;
  File? _newPhotoFile;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FOTOS ---
  Future<void> _pickProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _newPhotoFile = File(picked.path));
  }

  // --- LÓGICA DE GUARDADO ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final svc = ref.read(employeeServiceProvider);
      String? photoUrl;
      if (_newPhotoFile != null) {
        photoUrl = await svc.uploadProfilePhoto(_newPhotoFile!);
      }

      final phone = _phoneController.text.trim();
      await svc.updateProfile(
        telefono: phone.isEmpty ? null : phone,
        fotoPerfilUrl: photoUrl,
      );

      ref.invalidate(employeeProfileProvider);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _newPhotoFile = null;
      });
      _showSuccess('Perfil actualizado correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  // --- LÓGICA DE PASSWORD ---
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
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
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
    final profileAsync = ref.watch(employeeProfileProvider);
    final branchesAsync = ref.watch(employeeBranchesProvider);
    final complianceAsync = ref.watch(employeeComplianceAlertsProvider);
    final orgAsync = ref.watch(employeeOrganizationProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (profile) {
        // Resolver nombres
        final branchName = branchesAsync.maybeWhen(
          data: (branches) {
            if (profile.sucursalId == null) return null;
            final match = branches.where((b) => b.id == profile.sucursalId).toList();
            return match.isEmpty ? null : match.first.nombre;
          },
          orElse: () => null,
        );
        final orgName = orgAsync.valueOrNull?.razonSocial ?? 'Mi Organización';
        final currentUserEmail = Supabase.instance.client.auth.currentUser?.email ?? '';

        // Sync controlador
        if (!_isEditing && _phoneController.text.isEmpty) {
          _phoneController.text = profile.telefono ?? '';
        }

        return SharedProfileScaffold(
          userName: '${profile.nombres} ${profile.apellidos}',
          userEmail: currentUserEmail,
          initials: profile.nombres.isNotEmpty ? profile.nombres[0].toUpperCase() : '?',
          photoUrl: _newPhotoFile != null ? null : profile.fotoPerfilUrl, 
          isEditing: _isEditing,
          onEditPhoto: _pickProfilePhoto,
          
          // Action Buttons (Sin notificaciones)
          actions: [
            if (!_isEditing)
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              IconButton(
                tooltip: 'Cancelar',
                icon: const Icon(Icons.close_rounded),
                onPressed: _isSaving ? null : () => setState(() {
                  _isEditing = false;
                  _newPhotoFile = null;
                  _phoneController.text = profile.telefono ?? '';
                }),
              ),
          ],
          
          children: [
            // 1. Datos Personales
            Form(
              key: _formKey,
              child: ProfileSectionCard(
                title: 'Mis Datos',
                icon: Icons.person_rounded,
                children: [
                   ProfileInfoChip(
                    label: 'Cédula',
                    value: profile.cedula ?? 'No registrada',
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 12),
                  
                  // Teléfono Editable
                  ProfileTextField(
                    label: 'Teléfono',
                    controller: _phoneController,
                    enabled: _isEditing,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v?.length ?? 0) > 0 && (v!.length < 7) ? 'Inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  ProfileInfoChip(
                    label: 'Sucursal',
                    value: branchName ?? 'Sin asignar',
                    icon: Icons.store_mall_directory_rounded,
                  ),
                  const SizedBox(height: 12),
                  
                  ProfileInfoChip(
                    label: 'Organización',
                    value: orgName,
                    icon: Icons.apartment_rounded,
                  ),

                  // Botón Guardar
                  if (_isEditing) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                         style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                        child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Cumplimiento (Solo Empleado)
            ProfileSectionCard(
              title: 'Cumplimiento',
              icon: Icons.shield_rounded,
              trailing: _TinyBadge(
                count: complianceAsync.valueOrNull
                      ?.where((a) => (a.estado ?? '').toLowerCase() == 'pendiente')
                      .length ?? 0
              ),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alertas de auditoría', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Revisar si tienes llamados de atención pendientes.'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.neutral500),
                  onTap: () {
                     Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EmployeeComplianceAlertsView(),
                          ),
                        );
                  },
                )
              ],
            ),

            // 3. Seguridad (Nueva sección con Cambio de Password y Logout)
            ProfileSectionCard(
              title: 'Seguridad',
              icon: Icons.security_rounded,
              children: [
                ProfileInfoChip(
                  label: 'Correo electrónico',
                  value: currentUserEmail,
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
                  onPressed: _isSaving ? null : _signOut,
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
}

class _TinyBadge extends StatelessWidget {
  final int count;
  const _TinyBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
