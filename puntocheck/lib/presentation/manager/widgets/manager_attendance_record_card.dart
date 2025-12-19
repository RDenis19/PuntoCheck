import 'package:flutter/material.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/geofence_badge.dart';
import 'package:puntocheck/presentation/admin/widgets/type_badge.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerAttendanceRecordCard extends StatelessWidget {
  final RegistrosAsistencia record;
  final bool isLate;
  final bool missingExit;
  final VoidCallback? onTap;
  final VoidCallback? onViewEvidence;

  const ManagerAttendanceRecordCard({
    super.key,
    required this.record,
    this.isLate = false,
    this.missingExit = false,
    this.onTap,
    this.onViewEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final employeeName = record.perfilNombreCompleto;
    final branchName =
        record.sucursalNombre ??
        (record.sucursalId == null ? 'Sin sucursal' : 'Sucursal');
    final turnoLabel = record.turnoNombreTurno;

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
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  if (isLate)
                    _MiniBadge(
                      label: 'Tarde',
                      icon: Icons.schedule_outlined,
                      background: AppColors.warningOrange.withValues(
                        alpha: 0.12,
                      ),
                      foreground: AppColors.warningOrange,
                    ),
                  if (missingExit && record.tipoRegistro == 'entrada')
                    _MiniBadge(
                      label: 'Falta salida',
                      icon: Icons.logout_outlined,
                      background: AppColors.errorRed.withValues(alpha: 0.10),
                      foreground: AppColors.errorRed,
                    ),
                ],
              ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              if (turnoLabel != null && turnoLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timelapse_outlined,
                      size: 14,
                      color: AppColors.neutral500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Turno: $turnoLabel',
                        style: const TextStyle(
                          color: AppColors.neutral600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (record.notasSistema != null &&
                  record.notasSistema!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  record.notasSistema!.trim(),
                  style: const TextStyle(
                    color: AppColors.neutral700,
                    fontSize: 12,
                  ),
                ),
              ],
              if (record.evidenciaFotoUrl.trim().isNotEmpty &&
                  onViewEvidence != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onViewEvidence,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Ver evidencia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
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
        return 'Sync';
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
        borderRadius: BorderRadius.circular(10),
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
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
