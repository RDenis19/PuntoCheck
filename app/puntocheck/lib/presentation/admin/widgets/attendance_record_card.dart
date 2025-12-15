import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/geofence_badge.dart';
import 'package:puntocheck/presentation/admin/widgets/type_badge.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card moderno para mostrar un registro de asist encia individual
class AttendanceRecordCard extends ConsumerWidget {
  final RegistrosAsistencia record;
  final VoidCallback? onTap;

  const AttendanceRecordCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(orgAdminPersonProvider(record.perfilId));
    final branchesAsync = ref.watch(orgAdminBranchesProvider);
    final branchName = record.sucursalId == null
        ? 'Sin sucursal'
        : branchesAsync.maybeWhen(
            data: (branches) {
              for (final branch in branches) {
                if (branch.id == record.sucursalId) return branch.nombre;
              }
              return 'Sucursal desconocida';
            },
            orElse: () => 'Cargando sucursal...',
          );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.neutral200, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Empleado + Hora
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryRed.withValues(alpha: 0.8),
                          AppColors.primaryRed,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre empleado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        employeeAsync.when(
                          data: (employee) => Text(
                            '${employee.nombres} ${employee.apellidos}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text('Cargando...'),
                          error: (_, __) => Text(
                            'ID: ${record.perfilId.substring(0, 8)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(record.fechaHoraMarcacion),
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hora
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.neutral700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(record.fechaHoraMarcacion),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Badges: Tipo + Geocerca
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TypeBadge(type: record.tipoRegistro, compact: true),
                  GeofenceBadge(
                    isInside: record.estaDentroGeocerca,
                    precisionMeters: record.ubicacionPrecisionMetros,
                    compact: true,
                  ),
                  if (record.esMockLocation == true)
                    _MiniBadge(
                      label: 'Mock GPS',
                      icon: Icons.location_off_outlined,
                      background: AppColors.warningOrange.withValues(
                        alpha: 0.12,
                      ),
                      foreground: AppColors.warningOrange,
                    ),
                ],
              ),

              // Sucursal y origen
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 16,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      branchName,
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (record.origen != null) ...[
                    Icon(
                      _getOriginIcon(record.origen!.value),
                      size: 16,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getOriginLabel(record.origen!.value),
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),

              // Precisión GPS
              if (record.ubicacionPrecisionMetros != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Precisión: ${record.ubicacionPrecisionMetros!.toStringAsFixed(1)}m',
                      style: const TextStyle(
                        color: AppColors.neutral600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getOriginIcon(String origin) {
    switch (origin.toLowerCase()) {
      case 'gps_movil':
        return Icons.smartphone_rounded;
      case 'qr_fijo':
        return Icons.qr_code_2_rounded;
      case 'offline_sync':
        return Icons.cloud_sync_outlined;
      default:
        return Icons.device_unknown;
    }
  }

  String _getOriginLabel(String origin) {
    switch (origin.toLowerCase()) {
      case 'gps_movil':
        return 'GPS';
      case 'qr_fijo':
        return 'QR';
      case 'offline_sync':
        return 'Offline';
      default:
        return origin;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _MiniBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
