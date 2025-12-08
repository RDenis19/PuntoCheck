import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminPersonDetailView extends ConsumerWidget {
  final String userId;
  const OrgAdminPersonDetailView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(orgAdminPersonProvider(userId));
    final attendanceAsync = ref.watch(orgAdminPersonAttendanceProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de empleado'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(orgAdminPersonProvider(userId));
          ref.invalidate(orgAdminPersonAttendanceProvider(userId));
          await Future.wait([
            ref.read(orgAdminPersonProvider(userId).future),
            ref.read(orgAdminPersonAttendanceProvider(userId).future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            perfilAsync.when(
              data: (perfil) => _HeaderCard(perfil: perfil),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _ErrorTile(
                message: 'Error cargando empleado: $e',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Historial de asistencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
            ),
            const SizedBox(height: 8),
            attendanceAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const _EmptyAttendance();
                }
                return Column(
                  children: logs.map((log) => _AttendanceItem(log: log)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorTile(
                message: 'Error cargando asistencia: $e',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Perfiles perfil;
  const _HeaderCard({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final chipMaxWidth = MediaQuery.of(context).size.width * 0.45;
    final initials =
        '${perfil.nombres.isNotEmpty ? perfil.nombres[0] : ''}${perfil.apellidos.isNotEmpty ? perfil.apellidos[0] : ''}'
            .toUpperCase();
    final active = perfil.activo != false;
    final emailLabel =
        perfil.correo?.isNotEmpty == true ? perfil.correo! : 'Correo no disponible';
    final phoneLabel =
        perfil.telefono?.isNotEmpty == true ? perfil.telefono! : 'Sin teléfono';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryRed,
              child: ClipOval(
                child: perfil.fotoPerfilUrl != null &&
                        perfil.fotoPerfilUrl!.isNotEmpty
                    ? Image.network(
                        perfil.fotoPerfilUrl!,
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                      )
                    : Container(
                        color: AppColors.primaryRed.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isNotEmpty ? initials : '?',
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${perfil.nombres} ${perfil.apellidos}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        perfil.rol?.name ?? 'Sin rol',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.neutral700,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (perfil.cargo != null && perfil.cargo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    perfil.cargo!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutral700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.email_outlined,
                      label: emailLabel,
                      maxWidth: chipMaxWidth,
                    ),
                    _InfoChip(
                      icon: Icons.phone_outlined,
                      label: phoneLabel,
                      maxWidth: chipMaxWidth,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      active ? Icons.check_circle : Icons.cancel_outlined,
                      color: active ? Colors.green : AppColors.neutral500,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      active ? 'Activo' : 'Inactivo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                active ? Colors.green[700] : AppColors.neutral700,
                            fontWeight: FontWeight.w600,
                          ),
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
  final IconData icon;
  final String label;
  final double? maxWidth;
  const _InfoChip({
    required this.icon,
    required this.label,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final constraints = maxWidth != null
        ? BoxConstraints(maxWidth: maxWidth!)
        : const BoxConstraints();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ConstrainedBox(
        constraints: constraints,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.neutral600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceItem extends StatelessWidget {
  final RegistrosAsistencia log;
  const _AttendanceItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy · hh:mm a');
    final tipo = log.tipoRegistro ?? '';
    final icon = _iconForType(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.isEmpty ? 'Registro' : tipo.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral900,
                      ),
                ),
                const SizedBox(height: 2),
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
            Icon(
              log.estaDentroGeocerca! ? Icons.location_on : Icons.location_off,
              color:
                  log.estaDentroGeocerca! ? Colors.green : AppColors.neutral500,
              size: 18,
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'entrada':
        return Icons.login;
      case 'salida':
        return Icons.logout;
      case 'inicio_break':
        return Icons.coffee;
      case 'fin_break':
        return Icons.local_cafe_outlined;
      default:
        return Icons.access_time;
    }
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
            child: const Icon(
              Icons.history_toggle_off,
              size: 36,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay asistencias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aún no se registran marcaciones para este empleado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
