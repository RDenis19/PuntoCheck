import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_edit_person_view.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/presentation/common/widgets/confirm_dialog.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminPersonDetailView extends ConsumerStatefulWidget {
  final String userId;
  const OrgAdminPersonDetailView({super.key, required this.userId});

  @override
  ConsumerState<OrgAdminPersonDetailView> createState() =>
      _OrgAdminPersonDetailViewState();
}

class _OrgAdminPersonDetailViewState
    extends ConsumerState<OrgAdminPersonDetailView> {
  Future<void> _handleEdit(Perfiles perfil) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrgAdminEditPersonView(userId: widget.userId),
      ),
    );
    if (updated == true && mounted) {
      ref.invalidate(orgAdminPersonProvider(widget.userId));
      ref.invalidate(orgAdminStaffProvider);
    }
  }

  Future<void> _handleToggleActive(Perfiles perfil) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: perfil.activo == true ? 'Desactivar empleado' : 'Activar empleado',
      message: perfil.activo == true
          ? '¿Está seguro que desea desactivar a ${perfil.nombreCompleto}?\n\nNo podrá iniciar sesión ni registrar asistencia.'
          : '¿Está seguro que desea activar a ${perfil.nombreCompleto}?',
      confirmText: perfil.activo == true ? 'Desactivar' : 'Activar',
      isDestructive: perfil.activo == true,
    );

    if (!confirm || !mounted) return;

    try {
      final staff = ref.read(staffServiceProvider);
      await staff.updateProfile(
        widget.userId,
        {'activo': !(perfil.activo ?? true)},
      );
      ref.invalidate(orgAdminPersonProvider(widget.userId));
      ref.invalidate(orgAdminStaffProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        perfil.activo == true
            ? 'Empleado desactivado'
            : 'Empleado activado',
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    }
  }

  Future<void> _handleDelete(Perfiles perfil) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Eliminar empleado',
      message:
          '¿Está seguro que desea eliminar a ${perfil.nombreCompleto}?\n\nEsta acción marcará al empleado como eliminado.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (!confirm || !mounted) return;

    try {
      final staff = ref.read(staffServiceProvider);
      await staff.dismissEmployee(widget.userId);
      ref.invalidate(orgAdminStaffProvider);
      if (!mounted) return;
      showAppSnackBar(context, 'Empleado eliminado');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(orgAdminPersonProvider(widget.userId));
    final attendanceAsync =
        ref.watch(orgAdminPersonAttendanceProvider(widget.userId));
    final currentUserAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Detalle del empleado'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryRed),
        actions: [
          perfilAsync.whenOrNull(
            data: (perfil) {
              final currentUserId = currentUserAsync.value?.id;
              final isOwnProfile = currentUserId == widget.userId;

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (isOwnProfile &&
                      (value == 'delete' || value == 'toggle_active')) {
                    showAppSnackBar(
                      context,
                      'No puedes ${value == 'delete' ? 'eliminar' : 'desactivar'} tu propio perfil',
                      success: false,
                    );
                    return;
                  }

                  switch (value) {
                    case 'edit':
                      _handleEdit(perfil);
                      break;
                    case 'toggle_active':
                      _handleToggleActive(perfil);
                      break;
                    case 'delete':
                      _handleDelete(perfil);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  if (!isOwnProfile)
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            perfil.activo == true
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            perfil.activo == true ? 'Desactivar' : 'Activar',
                          ),
                        ],
                      ),
                    ),
                  if (!isOwnProfile)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(orgAdminPersonProvider(widget.userId));
          ref.invalidate(orgAdminPersonAttendanceProvider(widget.userId));
          await Future.wait([
            ref.read(orgAdminPersonProvider(widget.userId).future),
            ref.read(orgAdminPersonAttendanceProvider(widget.userId).future),
          ]);
        },
        child: perfilAsync.when(
          data: (perfil) => _DetailContent(
            perfil: perfil,
            attendanceAsync: attendanceAsync,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: 'Error cargando empleado: $e'),
        ),
      ),
    );
  }
}

// ============================================================================
// Contenido principal del detalle
// ============================================================================
class _DetailContent extends StatelessWidget {
  final Perfiles perfil;
  final AsyncValue<List<RegistrosAsistencia>> attendanceAsync;

  const _DetailContent({
    required this.perfil,
    required this.attendanceAsync,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderSection(perfil: perfil),
        const SizedBox(height: 20),
        _PersonalInfoSection(perfil: perfil),
        const SizedBox(height: 24),
        _AttendanceSection(attendanceAsync: attendanceAsync),
      ],
    );
  }
}

// ============================================================================
// Sección de encabezado con avatar y nombre
// ============================================================================
class _HeaderSection extends StatelessWidget {
  final Perfiles perfil;
  const _HeaderSection({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final initials = '${perfil.nombres.isNotEmpty ? perfil.nombres[0] : ''}'
            '${perfil.apellidos.isNotEmpty ? perfil.apellidos[0] : ''}'
        .toUpperCase();
    final active = perfil.activo != false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: perfil.fotoPerfilUrl != null &&
                      perfil.fotoPerfilUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        perfil.fotoPerfilUrl!,
                        fit: BoxFit.cover,
                        width: 84,
                        height: 84,
                      ),
                    )
                  : Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Nombre completo
          Text(
            perfil.nombreCompleto,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              perfil.rol?.value.toUpperCase() ?? 'SIN ROL',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Estado activo/inactivo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.greenAccent : Colors.white60,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                active ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Sección de información personal
// ============================================================================
class _PersonalInfoSection extends StatelessWidget {
  final Perfiles perfil;
  const _PersonalInfoSection({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Información Personal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
          ),
        ),
        _InfoCard(
          children: [
            _InfoItem(
              icon: Icons.email_rounded,
              iconColor: AppColors.neutral600,
              label: 'Correo electrónico',
              value: (perfil.email ?? perfil.correo) ?? 'No registrado',
            ),
            const Divider(height: 24),
            _InfoItem(
              icon: Icons.phone_rounded,
              iconColor: AppColors.neutral600,
              label: 'Teléfono',
              value: perfil.telefono ?? 'No registrado',
            ),
            const Divider(height: 24),
            _InfoItem(
              icon: Icons.badge_rounded,
              iconColor: AppColors.neutral600,
              label: 'Cédula',
              value: perfil.cedula ?? 'No registrado',
            ),
            const Divider(height: 24),
            _InfoItem(
              icon: Icons.work_rounded,
              iconColor: AppColors.neutral600,
              label: 'Cargo',
              value: perfil.cargo?.isNotEmpty == true
                  ? perfil.cargo!
                  : 'No asignado',
            ),
            const Divider(height: 24),
            _BranchInfo(perfil: perfil),
            if (perfil.creadoEn != null) ...[
              const Divider(height: 24),
              _InfoItem(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.neutral600,
                label: 'Fecha de ingreso',
                value: DateFormat('dd/MM/yyyy').format(perfil.creadoEn!),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Sección de historial de asistencia
// ============================================================================
class _AttendanceSection extends StatelessWidget {
  final AsyncValue<List<RegistrosAsistencia>> attendanceAsync;
  const _AttendanceSection({required this.attendanceAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                'Historial de Asistencia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
              ),
              const Spacer(),
              attendanceAsync.whenOrNull(
                data: (logs) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${logs.length}',
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ) ??
                  const SizedBox.shrink(),
            ],
          ),
        ),
        attendanceAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const _EmptyAttendance();
            }
            return Column(
              children: logs.map((log) => _AttendanceCard(log: log)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const _ErrorView(message: 'Error cargando asistencia'),
        ),
      ],
    );
  }
}

// ============================================================================
// Card contenedor de información
// ============================================================================
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ============================================================================
// Item de información individual
// ============================================================================
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Card de asistencia individual
// ============================================================================
class _AttendanceCard extends StatelessWidget {
  final RegistrosAsistencia log;
  const _AttendanceCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy - hh:mm a');
    final tipo = log.tipoRegistro ?? '';
    final icon = _iconForType(tipo);
    final color = _colorForType(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForType(tipo),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(log.fechaHoraMarcacion.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral700,
                      ),
                ),
              ],
            ),
          ),
          if (log.estaDentroGeocerca != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: log.estaDentroGeocerca!
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                log.estaDentroGeocerca!
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: log.estaDentroGeocerca! ? Colors.green : Colors.orange,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'entrada':
        return Icons.login_rounded;
      case 'salida':
        return Icons.logout_rounded;
      case 'inicio_break':
        return Icons.coffee_rounded;
      case 'fin_break':
        return Icons.free_breakfast_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'entrada':
        return Colors.green;
      case 'salida':
        return Colors.blue;
      case 'inicio_break':
        return Colors.orange;
      case 'fin_break':
        return Colors.purple;
      default:
        return AppColors.neutral600;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'inicio_break':
        return 'Inicio de Descanso';
      case 'fin_break':
        return 'Fin de Descanso';
      default:
        return 'Registro';
    }
  }
}

// ============================================================================
// Estado vacío de asistencia
// ============================================================================
class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral200,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin registros de asistencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este empleado aún no ha registrado\nninguna marcación',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral700,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Vista de error
// ============================================================================
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Item de información con carga asíncrona (para jefe inmediato)
// ============================================================================
class _BranchInfo extends ConsumerWidget {
  const _BranchInfo({required this.perfil});

  final Perfiles perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(orgAdminBranchesProvider);
    final branchId = perfil.sucursalId;

    return branchesAsync.when(
      data: (branches) {
        final branch = branches.firstWhere(
          (b) => b.id == branchId,
          orElse: () => Sucursales(
            id: '',
            organizacionId: perfil.organizacionId ?? '',
            nombre: 'Sin sucursal',
          ),
        );
        return _InfoItem(
          icon: Icons.store_mall_directory_outlined,
          iconColor: AppColors.neutral600,
          label: 'Sucursal',
          value: branchId == null ? 'Sin sucursal' : branch.nombre,
        );
      },
      loading: () => const _InfoItem(
        icon: Icons.store_mall_directory_outlined,
        iconColor: AppColors.neutral600,
        label: 'Sucursal',
        value: 'Cargando...',
      ),
      error: (e, _) => _InfoItem(
        icon: Icons.store_mall_directory_outlined,
        iconColor: AppColors.errorRed,
        label: 'Sucursal',
        value: 'Error: $e',
      ),
    );
  }
}
