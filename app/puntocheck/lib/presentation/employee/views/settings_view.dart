import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/services/storage_service.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({
    super.key,
    this.embedded = false,
    this.personalInfoRoute = AppRoutes.personalInfo,
    this.showSignOut = true,
  });

  final bool embedded;
  final String personalInfoRoute;
  final bool showSignOut;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _imagePicker = SafeImagePicker();
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    final content = ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, widget.embedded ? 100 : 20),
      children: [
        profileAsync.when(
          data: (profile) => _ProfileHeader(
            fullName: profile?.fullName ?? 'Usuario',
            email: profile?.email ?? 'Sin correo',
            jobTitle: profile?.jobTitle ?? '',
            initials: profile?.initials ?? 'NA',
            avatarUrl: profile?.avatarUrl,
            isUploading: _isUploadingAvatar,
            onEditAvatar: profile == null ? null : _pickAvatar,
          ),
          loading: () => const _ProfileHeader.loading(),
          error: (_, __) => _ProfileHeader(
            fullName: 'Usuario',
            email: 'Sin correo',
            jobTitle: '',
            initials: 'NA',
            isUploading: false,
            onEditAvatar: () => _showSnackBar(context, 'Actualiza tu foto en Perfil.'),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Cuenta'),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Informacion personal',
          subtitle: 'Edita tu nombre, telefono o cargo',
          onTap: () {
            context.push(widget.personalInfoRoute);
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Preferencia'),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Modo Oscuro',
          subtitle: 'Cambia la apariencia del sistema',
          onTap: () {
            _showSnackBar(context, 'Modo oscuro en desarrollo.');
          },
        ),
        _SettingsTile(
          icon: Icons.language,
          title: 'Lenguaje',
          subtitle: 'Selecciona tu idioma preferido',
          onTap: () {
            _showSnackBar(context, 'Cambio de lenguaje en desarrollo.');
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Soporte'),
        _SettingsTile(
          icon: Icons.fingerprint,
          title: 'Huella Dactilar',
          subtitle: 'Configura biometria para ingresar',
          onTap: () {
            _showSnackBar(context, 'Huella dactilar en desarrollo.');
          },
        ),
        const SizedBox(height: 32),
        if (widget.showSignOut)
          OutlinedDarkButton(
            text: 'Cerrar sesion',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
            },
          ),
      ],
    );

    if (widget.embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Configuracion Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
      ),
      body: content,
    );
  }

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

  Future<void> _pickAvatar() async {
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
        _showSnackBar(context, 'Permiso denegado. Habilitalo en ajustes.');
        if (result.permanentlyDenied) {
          openAppSettings();
        }
      }
      return;
    }

    if (result.errorMessage != null) {
      if (mounted) {
        _showSnackBar(
            context, 'No se pudo abrir la camara/galeria: ${result.errorMessage}');
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
      if (!mounted) return;
      _showSnackBar(context, 'Foto de perfil actualizada');
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'No se pudo subir la foto: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.onEditAvatar,
    this.fullName = '',
    this.email = '',
    this.jobTitle = '',
    this.initials = 'NA',
    this.avatarUrl,
    this.isUploading = false,
  });

  const _ProfileHeader.loading()
    : onEditAvatar = null,
      fullName = 'Cargando...',
      email = '',
      jobTitle = '',
      initials = 'NA',
      avatarUrl = null,
      isUploading = false;

  final VoidCallback? onEditAvatar;
  final String fullName;
  final String email;
  final String jobTitle;
  final String initials;
  final String? avatarUrl;
  final bool isUploading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FutureBuilder<String?>(
                future: avatarUrl == null || avatarUrl!.isEmpty
                    ? Future.value(null)
                    : ref
                        .read(storageServiceProvider)
                        .resolveAvatarUrl(avatarUrl!, expiresInSeconds: 3600),
                builder: (context, snapshot) {
                  final url = snapshot.data ?? avatarUrl;
                  return CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                    backgroundImage:
                        (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                    child: (url == null || url.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  );
                },
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onEditAvatar,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
                if (jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    jobTitle,
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.backgroundDark,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: AppColors.white,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRed),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.black.withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      ),
    );
  }
}
