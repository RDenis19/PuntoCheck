import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class PersonalInfoView extends ConsumerStatefulWidget {
  const PersonalInfoView({super.key});

  @override
  ConsumerState<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends ConsumerState<PersonalInfoView> {
  bool _isSaving = false;

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
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carga de foto disponible al conectar almacenamiento.')),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
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
                  const SnackBar(content: Text('Actualiza tu clave desde el flujo de recuperacion.')),
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
          if (_isSaving)
            const Center(child: CircularProgressIndicator()),
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

