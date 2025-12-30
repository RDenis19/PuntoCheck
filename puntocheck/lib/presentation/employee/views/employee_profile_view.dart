import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puntocheck/presentation/employee/views/employee_compliance_alerts_view.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_notifications_action.dart';
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
    final complianceAsync = ref.watch(employeeComplianceAlertsProvider);
    final orgAsync = ref.watch(employeeOrganizationProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.neutral900,
        actions: [
          const EmployeeNotificationsAction(),
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

          final org = orgAsync.valueOrNull;
          final orgName = org?.razonSocial;
          final orgRuc = org?.ruc;
          final orgLabel = orgName ??
              (orgAsync.hasError
                  ? 'Sin permisos para ver el nombre (RLS)'
                  : _shortId(profile.organizacionId));

          if (!_isEditing && _phoneController.text.isEmpty) {
            _phoneController.text = profile.telefono ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _ProfileHeaderCard(
                    isEditing: _isEditing,
                    isSaving: _isSaving,
                    newPhotoFile: _newPhotoFile,
                    fotoPerfilUrl: profile.fotoPerfilUrl,
                    initials: profile.nombres.isNotEmpty
                        ? profile.nombres[0].toUpperCase()
                        : '?',
                    fullName: '${profile.nombres} ${profile.apellidos}',
                    role: profile.cargo ?? 'Empleado',
                    orgName: orgLabel,
                    branchName: branchName ?? _shortId(profile.sucursalId),
                    onPickPhoto: _pickProfilePhoto,
                    onRefreshOrg: () => ref.invalidate(employeeOrganizationProvider),
                  ),
                  const SizedBox(height: 14),
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
                          value: Supabase.instance.client.auth.currentUser?.email ?? '—',
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
                          value: orgLabel.isEmpty ? 'No asignada' : orgLabel,
                          icon: Icons.apartment_outlined,
                        ),
                        const Divider(height: 24),
                        _readOnlyRow(
                          label: 'RUC',
                          value: orgRuc ?? '—',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Cumplimiento',
                    child: _ComplianceEntry(
                      pendingCount: complianceAsync.valueOrNull
                              ?.where((a) =>
                                  (a.estado ?? '').trim().toLowerCase() ==
                                  'pendiente')
                              .length ??
                          0,
                      isLoading: complianceAsync.isLoading,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EmployeeComplianceAlertsView(),
                          ),
                        );
                      },
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

String _shortId(String? id) {
  final v = (id ?? '').trim();
  if (v.isEmpty) return '—';
  return v.length > 8 ? '${v.substring(0, 8)}...' : v;
}

class _ComplianceEntry extends StatelessWidget {
  const _ComplianceEntry({
    required this.pendingCount,
    required this.isLoading,
    required this.onTap,
  });

  final int pendingCount;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        pendingCount > 0 ? AppColors.warningOrange : AppColors.successGreen;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertas de cumplimiento',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ver alertas que te afectan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
              ] else ...[
                _TinyBadge(count: pendingCount),
                const SizedBox(width: 10),
              ],
              const Icon(Icons.chevron_right, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = count > 0 ? AppColors.warningOrange : AppColors.successGreen;
    final label = count > 0 ? '$count' : 'OK';
    final icon = count > 0 ? Icons.warning_amber_rounded : Icons.check_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.isEditing,
    required this.isSaving,
    required this.newPhotoFile,
    required this.fotoPerfilUrl,
    required this.initials,
    required this.fullName,
    required this.role,
    required this.orgName,
    required this.branchName,
    required this.onPickPhoto,
    required this.onRefreshOrg,
  });

  final bool isEditing;
  final bool isSaving;
  final File? newPhotoFile;
  final String? fotoPerfilUrl;
  final String initials;
  final String fullName;
  final String role;
  final String orgName;
  final String branchName;
  final VoidCallback onPickPhoto;
  final VoidCallback onRefreshOrg;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? imageProvider = newPhotoFile != null
        ? FileImage(newPhotoFile!) as ImageProvider<Object>
        : ((fotoPerfilUrl != null && fotoPerfilUrl!.isNotEmpty)
            ? NetworkImage(fotoPerfilUrl!) as ImageProvider<Object>
            : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                        ),
                      )
                    : null,
              ),
              if (isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: AppColors.primaryRed,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: isSaving ? null : onPickPhoto,
                      tooltip: 'Cambiar foto',
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
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.apartment_outlined,
                      label: orgName,
                      onLongPress: onRefreshOrg,
                    ),
                    _InfoChip(
                      icon: Icons.store_mall_directory_outlined,
                      label: branchName,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.neutral600),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
