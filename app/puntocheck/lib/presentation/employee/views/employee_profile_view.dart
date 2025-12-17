import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/auth_providers.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _newPhotoFile = File(picked.path));
  }

  Future<void> _startEditing(String? phone) async {
    setState(() {
      _isEditing = true;
      _newPhotoFile = null;
      _phoneController.text = phone ?? '';
    });
  }

  void _cancelEditing(String? phone) {
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _newPhotoFile = null;
      _phoneController.text = phone ?? '';
    });
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(employeeProfileProvider);
    final branchesAsync = ref.watch(employeeBranchesProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.neutral900,
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => _isEditing
                ? IconButton(
                    tooltip: 'Cancelar',
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => _cancelEditing(profile.telefono),
                  )
                : IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _startEditing(profile.telefono),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          final branchName = branchesAsync.maybeWhen(
            data: (branches) {
              if (profile.sucursalId == null) return null;
              final match = branches.where((b) => b.id == profile.sucursalId).toList();
              return match.isEmpty ? null : match.first.nombre;
            },
            orElse: () => null,
          );

          if (!_isEditing && _phoneController.text.isEmpty) {
            _phoneController.text = profile.telefono ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
                          backgroundImage: _newPhotoFile != null
                              ? FileImage(_newPhotoFile!)
                              : (profile.fotoPerfilUrl != null && profile.fotoPerfilUrl!.isNotEmpty
                                  ? NetworkImage(profile.fotoPerfilUrl!)
                                  : null) as ImageProvider<Object>?,
                          child: (_newPhotoFile == null) &&
                                  (profile.fotoPerfilUrl == null || profile.fotoPerfilUrl!.isEmpty)
                              ? Text(
                                  profile.nombres.isNotEmpty
                                      ? profile.nombres[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryRed,
                                  ),
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primaryRed,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: _isSaving ? null : _pickProfilePhoto,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${profile.nombres} ${profile.apellidos}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.cargo ?? 'Empleado',
                    style: const TextStyle(color: AppColors.neutral600),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Datos',
                    child: Column(
                      children: [
                        _readOnlyRow(
                          label: 'Cédula',
                          value: profile.cedula ?? 'No registrada',
                          icon: Icons.badge_outlined,
                        ),
                        const Divider(height: 24),
                        _editableRow(
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          child: TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing && !_isSaving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Opcional',
                              border: InputBorder.none,
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return null;
                              if (value.length < 7) return 'Teléfono inválido';
                              return null;
                            },
                          ),
                        ),
                        const Divider(height: 24),
                        _readOnlyRow(
                          label: 'Email',
                          value: Supabase.instance.client.auth.currentUser?.email ?? '',
                          icon: Icons.email_outlined,
                        ),
                        const Divider(height: 24),
                        _readOnlyRow(
                          label: 'Sucursal',
                          value: branchName ?? (profile.sucursalId ?? 'No asignada'),
                          icon: Icons.store_mall_directory_outlined,
                        ),
                        const Divider(height: 24),
                        _readOnlyRow(
                          label: 'Organización',
                          value: profile.organizacionId ?? 'No asignada',
                          icon: Icons.apartment_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar cambios',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _signOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cerrar sesión'),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (_isEditing)
                    const Text(
                      'Solo puedes actualizar tu teléfono y foto de perfil.',
                      style: TextStyle(color: AppColors.neutral600),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _readOnlyRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neutral600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.neutral900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editableRow({
    required String label,
    required IconData icon,
    required bool enabled,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: enabled ? AppColors.primaryRed : AppColors.neutral600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral700,
                ),
              ),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
