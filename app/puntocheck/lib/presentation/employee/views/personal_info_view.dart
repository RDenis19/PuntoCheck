import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/services/storage_service.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';

class PersonalInfoView extends ConsumerStatefulWidget {
  const PersonalInfoView({super.key});

  @override
  ConsumerState<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends ConsumerState<PersonalInfoView> {
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  final _imagePicker = SafeImagePicker();

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  Future<void> _recoverLostImage() async {
    final file = await _imagePicker.recoverLostImage();
    if (file != null) {
      _uploadAvatarFile(file);
    }
  }

  Future<String?> _resolveAvatarUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    return ref
        .read(storageServiceProvider)
        .resolveAvatarUrl(rawUrl, expiresInSeconds: 3600);
  }

  Future<void> _pickAvatar(Profile profile) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final result = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
    );

    if (result.permissionDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permiso denegado. Habilitalo en ajustes.')),
        );
        if (result.permanentlyDenied) {
          openAppSettings();
        }
      }
      return;
    }

    if (result.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No se pudo abrir la camara/galeria: ${result.errorMessage}')),
        );
      }
      return;
    }

    final file = result.file;
    if (file == null) return;

    _uploadAvatarFile(file);
  }

  Future<void> _uploadAvatarFile(File file) async {
    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(profileProvider.notifier).uploadAvatar(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Informacion Personal',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) => _buildContent(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar perfil')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Profile? profile) {
    if (profile == null) {
      return const Center(child: Text('Perfil no disponible'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                FutureBuilder<String?>(
                  future: _resolveAvatarUrl(profile.avatarUrl),
                  builder: (context, snapshot) {
                    final avatarUrl = snapshot.data ?? profile.avatarUrl;
                    return CircleAvatar(
                      radius: 56,
                      backgroundColor:
                          AppColors.primaryRed.withValues(alpha: 0.08),
                      backgroundImage: (avatarUrl != null &&
                              avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              profile.initials,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryRed,
                              ),
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _isUploadingAvatar ? null : () => _pickAvatar(profile),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Datos personales', Icons.person_outline),
          const SizedBox(height: 12),
          _InfoEditableField(
            label: 'Nombre',
            value: profile.fullName ?? 'Sin nombre',
            onEdit: () => _openEditModal(
              title: 'Editar nombre',
              initialValue: profile.fullName ?? '',
              onSave: (value) => _updateProfile(profile, fullName: value),
            ),
          ),
          _InfoEditableField(
            label: 'Cargo',
            value: profile.jobTitle,
            onEdit: () => _openEditModal(
              title: 'Editar cargo',
              initialValue: profile.jobTitle,
              onSave: (value) => _updateProfile(profile, jobTitle: value),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Informacion de contacto', Icons.mail_outline),
          const SizedBox(height: 12),
          _InfoEditableField(
            label: 'Correo Electronico',
            value: profile.email ?? 'Sin correo',
            onEdit: null,
          ),
          _InfoEditableField(
            label: 'Telefono',
            value: profile.phone ?? 'Sin telefono',
            onEdit: () => _openEditModal(
              title: 'Editar telefono',
              initialValue: profile.phone ?? '',
              onSave: (value) => _updateProfile(profile, phone: value),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Seguridad', Icons.lock_outline),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListTile(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Actualiza tu clave desde el flujo de recuperacion.')),
                );
              },
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: AppColors.primaryRed,
                ),
              ),
              title: const Text(
                'Cambiar Contrasena',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
              subtitle: Text(
                'Solicita un restablecimiento para modificarla.',
                style: TextStyle(
                  color: AppColors.black.withValues(alpha: 0.6),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isSaving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfile(
    Profile profile, {
    String? fullName,
    String? phone,
    String? jobTitle,
  }) async {
    setState(() => _isSaving = true);
    try {
      final updated = profile.copyWith(
        fullName: fullName,
        phone: phone,
        jobTitle: jobTitle,
      );
      await ref.read(profileProvider.notifier).updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  Future<void> _openEditModal({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Guardar',
                onPressed: () {
                  onSave(controller.text.trim());
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoEditableField extends StatelessWidget {
  const _InfoEditableField({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryRed),
            ),
        ],
      ),
    );
  }
}
