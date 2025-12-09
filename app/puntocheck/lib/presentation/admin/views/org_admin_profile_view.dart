import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista profesional de perfil de administrador de organización
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Perfil actualizado exitosamente'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Contraseña actualizada'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
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

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (e, _) => _ErrorState(message: 'Error cargando perfil: $e'),
        data: (perfil) {
          if (perfil == null) {
            return const _ErrorState(message: 'No se encontró el perfil');
          }

          final nombresCtrl = TextEditingController(text: perfil.nombres);
          final apellidosCtrl = TextEditingController(text: perfil.apellidos);
          final cargoCtrl = TextEditingController(text: perfil.cargo ?? '');
          final telefonoCtrl = TextEditingController(text: perfil.telefono ?? '');

          return CustomScrollView(
            slivers: [
              // App Bar con gradiente rojo
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.primaryRed,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryRed,
                          Color(0xFFB71C1C), // Rojo más oscuro
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                child: Text(
                                  perfil.nombres.isNotEmpty
                                      ? perfil.nombres[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Nombre
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '${perfil.nombres} ${perfil.apellidos}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Email
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      tooltip: 'Editar perfil',
                    ),
                ],
              ),

              // Contenido
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Datos Personales
                    _buildProfileInfoSection(
                      perfil,
                      nombresCtrl,
                      apellidosCtrl,
                      cargoCtrl,
                      telefonoCtrl,
                    ),

                    const SizedBox(height: 16),

                    // Organización
                    _buildOrganizationSection(orgAsync),

                    const SizedBox(height: 16),

                    // Seguridad
                    _buildSecuritySection(user),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileInfoSection(
    perfil,
    TextEditingController nombresCtrl,
    TextEditingController apellidosCtrl,
    TextEditingController cargoCtrl,
    TextEditingController telefonoCtrl,
  ) {
    return _ModernCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _ModernTextField(
              label: 'Nombres',
              controller: nombresCtrl,
              enabled: _isEditing,
              icon: Icons.badge_outlined,
              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),

            _ModernTextField(
              label: 'Apellidos',
              controller: apellidosCtrl,
              enabled: _isEditing,
              icon: Icons.badge_outlined,
              validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),

            _ModernTextField(
              label: 'Cargo',
              controller: cargoCtrl,
              enabled: _isEditing,
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 14),

            _ModernTextField(
              label: 'Teléfono',
              controller: telefonoCtrl,
              enabled: _isEditing,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),

            _InfoChip(
              label: 'Rol',
              value: 'Administrador de Organización',
              icon: Icons.admin_panel_settings,
            ),
            const SizedBox(height: 10),

            _InfoChip(
              label: 'Estado',
              value: (perfil.activo ?? true) ? 'Activo' : 'Inactivo',
              icon: Icons.circle,
              valueColor: (perfil.activo ?? true)
                  ? AppColors.successGreen
                  : AppColors.neutral500,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral700,
                        side: const BorderSide(color: AppColors.neutral300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationSection(AsyncValue orgAsync) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mi Organización',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          orgAsync.when(
            data: (org) => Column(
              children: [
                _InfoChip(
                  label: 'Nombre',
                  value: org.razonSocial,
                  icon: Icons.apartment,
                ),
                const SizedBox(height: 10),
                _InfoChip(
                  label: 'RUC',
                  value: org.ruc,
                  icon: Icons.numbers,
                ),
                const SizedBox(height: 10),
                _InfoChip(
                  label: 'Suscripción',
                  value: org.estadoSuscripcion?.value ?? 'N/D',
                  icon: Icons.verified_outlined,
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(user) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _InfoChip(
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
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
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
              side: const BorderSide(color: AppColors.errorRed, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final ctrl = TextEditingController();
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
                controller: ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
                ),
                validator: (v) {
                  if (v != ctrl.text) return 'Las contraseñas no coinciden';
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _changePassword(ctrl.text);
              }
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
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================

class _ModernCard extends StatelessWidget {
  final Widget child;

  const _ModernCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? AppColors.neutral300 : AppColors.neutral200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.errorRed),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
