import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminProfileView extends ConsumerStatefulWidget {
  const OrgAdminProfileView({super.key});

  @override
  ConsumerState<OrgAdminProfileView> createState() => _OrgAdminProfileViewState();
}

class _OrgAdminProfileViewState extends ConsumerState<OrgAdminProfileView> {
  bool _isSaving = false;

  Future<void> _updateProfile({
    required String userId,
    required String nombres,
    required String apellidos,
    required String cargo,
    required String telefono,
  }) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword(String newPassword) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updatePassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final orgAsync = ref.watch(orgAdminOrganizationProvider);
    final user = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error cargando perfil: $e')),
      data: (perfil) {
        if (perfil == null) {
          return const Center(child: Text('No se encontró el perfil.'));
        }
        final nombresCtrl = TextEditingController(text: perfil.nombres);
        final apellidosCtrl = TextEditingController(text: perfil.apellidos);
        final cargoCtrl = TextEditingController(text: perfil.cargo ?? '');
        final telefonoCtrl = TextEditingController(text: perfil.telefono ?? '');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                child: Text(
                  perfil.nombres.isNotEmpty ? perfil.nombres[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${perfil.nombres} ${perfil.apellidos}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral700,
                    ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Datos personales',
                child: Column(
                  children: [
                    _InputField(label: 'Nombres', controller: nombresCtrl),
                    const SizedBox(height: 10),
                    _InputField(label: 'Apellidos', controller: apellidosCtrl),
                    const SizedBox(height: 10),
                    _InputField(label: 'Cargo', controller: cargoCtrl),
                    const SizedBox(height: 10),
                    _InputField(label: 'Teléfono', controller: telefonoCtrl),
                    const SizedBox(height: 10),
                    _ReadonlyField(label: 'Rol', value: 'Admin de organización'),
                    const SizedBox(height: 6),
                    _ReadonlyField(
                      label: 'Estado',
                      value: (perfil.activo ?? true) ? 'Activo' : 'Inactivo',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _updateProfile(
                                userId: perfil.id,
                                nombres: nombresCtrl.text.trim(),
                                apellidos: apellidosCtrl.text.trim(),
                                cargo: cargoCtrl.text.trim(),
                                telefono: telefonoCtrl.text.trim(),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Cuenta y seguridad',
                child: Column(
                  children: [
                    _ReadonlyField(label: 'Correo', value: user?.email ?? ''),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => _showPasswordDialog(context),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Cambiar contraseña'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neutral600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : () => ref.read(authControllerProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout, color: AppColors.errorRed),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Mi organización',
                child: orgAsync.when(
                  data: (org) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadonlyField(label: 'Nombre', value: org.razonSocial),
                      const SizedBox(height: 8),
                      _ReadonlyField(label: 'RUC', value: org.ruc),
                      const SizedBox(height: 8),
                      _ReadonlyField(
                        label: 'Estado suscripción',
                        value: org.estadoSuscripcion?.value ?? 'N/D',
                      ),
                      const SizedBox(height: 8),
                      _ReadonlyField(
                        label: 'Plan',
                        value: org.planId ?? 'Sin plan',
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Text('Error cargando organización: $e'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
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
                    Navigator.of(context).pop();
                    await _changePassword(ctrl.text);
                  },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadonlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
