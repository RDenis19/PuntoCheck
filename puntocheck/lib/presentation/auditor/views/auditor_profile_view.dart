import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puntocheck/presentation/shared/views/shared_profile_scaffold.dart';
import 'package:puntocheck/presentation/shared/widgets/profile_widgets.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista UNIFICADA para Auditor.
/// Usa [SharedProfileScaffold].
class AuditorProfileView extends ConsumerStatefulWidget {
  const AuditorProfileView({super.key});

  @override
  ConsumerState<AuditorProfileView> createState() => _AuditorProfileViewState();
}

class _AuditorProfileViewState extends ConsumerState<AuditorProfileView> {
  final _imagePicker = SafeImagePicker();
  bool _isSaving = false;
  bool _isEditing = false;
  File? _newPhotoFile; // En auditor el perfil solo permite cambiar foto

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

    final result = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (!mounted) return;
    if (result.file != null) {
      setState(() => _newPhotoFile = result.file);
      // Guardar inmediatamente o preguntar (aquí lo haremos explícito como en los otros roles)
    }
  }

  Future<void> _savePhoto() async {
    final file = _newPhotoFile;
    if (file == null) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(auditorServiceProvider);
      final url = await service.uploadProfilePhoto(file);
      await service.updateMyProfile(fotoPerfilUrl: url);

      ref.invalidate(profileProvider); // Ojo: auditor tiene su provider específico? profileProvider general sirve

      if (!mounted) return;
      setState(() => _newPhotoFile = null);
      _showSuccess('Foto de perfil actualizada');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- PASSWORD Y LOGOUT ---

  Future<void> _showChangePasswordDialog() async {
    final newCtrl = TextEditingController();
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
                controller: newCtrl,
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
                validator: (v) => v != newCtrl.text ? 'No coinciden' : null,
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
            onPressed: _isSaving ? null : () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _changePassword(newCtrl.text);
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

  Future<void> _changePassword(String newPassword) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updatePassword(newPassword);
      if (!mounted) return;
      _showSuccess('Contraseña actualizada');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
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
    final profileAsync = ref.watch(auditorProfileProvider);
    final orgAsync = ref.watch(auditorOrganizationProvider);
    final branchesAsync = ref.watch(auditorBranchesProvider);
    final user = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error cargando perfil: $e')),
      ),
      data: (profile) {
        final branchName = branchesAsync.maybeWhen(
          data: (branches) {
            final id = profile.sucursalId;
            if (id == null || id.isEmpty) return null;
            final match = branches.where((b) => b.id == id).toList();
            return match.isEmpty ? null : match.first.nombre;
          },
          orElse: () => null,
        );

        final orgName = orgAsync.maybeWhen(
          data: (org) => org.razonSocial,
          orElse: () => profile.organizacionId?.isNotEmpty == true ? profile.organizacionId! : 'No asignada',
        );

        final initials = (profile.nombres.isNotEmpty ? profile.nombres[0] : '?').toUpperCase();
        
        // En Auditor solo se edita la foto desde la pantalla, no hay botón general de "Editar texto"
        // ya que el auditor suele tener datos fijos o gestionados por admin (comúnmente).
        // Pero mantenemos la UI consistente con el botón de "Camara" en el avatar.

        return SharedProfileScaffold(
          userName: profile.nombreCompleto,
          userEmail: user?.email ?? '',
          initials: initials,
          photoUrl: _newPhotoFile != null ? null : profile.fotoPerfilUrl, // TODO: FileImage si hay nuevo archivo
          isEditing: _isEditing, // Esto habilita el botón de cámara en el scaffold
          onEditPhoto: _pickProfilePhoto, 
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Editar perfil',
              )
            else
              IconButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditing = false;
                          _newPhotoFile = null;
                        });
                      },
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancelar',
              ),
          ], 
          
          children: [
            // Botón guardar foto si hay una seleccionada
            if (_newPhotoFile != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => setState(() => _newPhotoFile = null),
                       style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: const BorderSide(color: AppColors.neutral300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar Foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePhoto,
                       style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Guardar Foto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 1. Datos
            ProfileSectionCard(
              title: 'Mis Datos',
              icon: Icons.person_rounded,
              children: [
                ProfileInfoChip(
                  label: 'Rol', 
                  value: 'Auditor', 
                  icon: Icons.verified_user_rounded
                ),
                const SizedBox(height: 12),
                ProfileInfoChip(
                  label: 'Cédula', 
                  value: profile.cedula ?? 'No registrada', 
                  icon: Icons.badge_rounded
                ),
                const SizedBox(height: 12),
                ProfileInfoChip(
                  label: 'Sucursal', 
                  value: branchName ?? 'No asignada', 
                  icon: Icons.store_rounded
                ),
                const SizedBox(height: 12),
                ProfileInfoChip(
                  label: 'Organización', 
                  value: orgName, 
                  icon: Icons.apartment_rounded
                ),
              ],
            ),

            // 2. Seguridad
            ProfileSectionCard(
              title: 'Seguridad',
              icon: Icons.security_rounded,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _showChangePasswordDialog,
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
