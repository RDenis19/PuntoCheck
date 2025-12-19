import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorProfileView extends ConsumerStatefulWidget {
  const AuditorProfileView({super.key});

  @override
  ConsumerState<AuditorProfileView> createState() => _AuditorProfileViewState();
}

class _AuditorProfileViewState extends ConsumerState<AuditorProfileView> {
  final _imagePicker = SafeImagePicker();
  bool _isSaving = false;
  File? _newPhotoFile;

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
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
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

    if (result.permissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso denegado. Habilítalo en ajustes para continuar.'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (result.file == null) return;
    setState(() => _newPhotoFile = result.file);
  }

  Future<void> _savePhoto() async {
    final file = _newPhotoFile;
    if (file == null) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(auditorServiceProvider);
      final url = await service.uploadProfilePhoto(file);
      await service.updateMyProfile(fotoPerfilUrl: url);

      ref.invalidate(profileProvider);

      if (!mounted) return;
      setState(() => _newPhotoFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil actualizada'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primaryRed),
            SizedBox(width: 12),
            Text(
              'Cambiar contraseña',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
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
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.neutral100,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.neutral100,
                ),
                validator: (v) {
                  if (v != newCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(context).pop();
                    await _changePassword(newCtrl.text);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(auditorProfileProvider);
    final orgAsync = ref.watch(auditorOrganizationProvider);
    final branchesAsync = ref.watch(auditorBranchesProvider);
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          profileAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            ),
            error: (e, _) => SectionCard(
              title: 'Tu cuenta',
              child: Text(
                'No se pudo cargar el perfil.\n$e',
                style: const TextStyle(color: AppColors.errorRed),
              ),
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
                orElse: () => null,
              );

              final initials = (profile.nombres.isNotEmpty ? profile.nombres[0] : '?')
                  .toUpperCase();

              final photoUrl = profile.fotoPerfilUrl?.trim();

              return Column(
                children: [
                  SectionCard(
                    title: 'Tu cuenta',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: AppColors.neutral200,
                                  backgroundImage: _newPhotoFile != null
                                      ? FileImage(_newPhotoFile!)
                                      : (photoUrl != null && photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                  child: (photoUrl == null || photoUrl.isEmpty) &&
                                          _newPhotoFile == null
                                      ? Text(
                                          initials,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.neutral700,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _isSaving ? null : _pickProfilePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryRed,
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.nombreCompleto,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.neutral900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.cargo ?? 'Auditor',
                                    style: const TextStyle(color: AppColors.neutral700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_newPhotoFile != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => setState(() => _newPhotoFile = null),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _savePhoto,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Guardar foto'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Datos',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Rol',
                          value: 'Auditor',
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Cédula',
                          value: profile.cedula ?? 'No registrada',
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? 'No disponible',
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.store_outlined,
                          label: 'Sucursal',
                          value: branchName ?? (profile.sucursalId ?? 'No asignada'),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.apartment_outlined,
                          label: 'Organización',
                          value: orgName ??
                              (profile.organizacionId?.isNotEmpty == true
                                  ? profile.organizacionId!
                                  : 'No asignada'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Cuenta',
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _showChangePasswordDialog,
                            icon: const Icon(Icons.lock_reset),
                            label: const Text('Cambiar contraseña'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _signOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorRed,
                              side: const BorderSide(color: AppColors.errorRed),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Icon(icon, color: AppColors.neutral700, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
