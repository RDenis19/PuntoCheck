import 'package:flutter/material.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/geofence_badge.dart';
import 'package:puntocheck/presentation/admin/widgets/type_badge.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AttendanceRecordCard extends StatelessWidget {
  final RegistrosAsistencia record;
  final VoidCallback? onTap;

  const AttendanceRecordCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final employeeName = record.perfilNombreCompleto;

    final branch = (record.sucursalNombre ?? '').trim();
    final branchLabel = branch.isNotEmpty
        ? branch
        : (record.sucursalId == null
              ? 'Sin sucursal'
              : 'Sucursal: ${_shortId(record.sucursalId!)}');

    final dateLabel = _formatDate(record.fechaHoraMarcacion);
    final timeLabel = _formatTime(record.fechaHoraMarcacion);

    final originValue = (record.origen?.value ?? '').trim();
    final originLabel = originValue.isEmpty ? null : _originLabel(originValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$branchLabel • $dateLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.neutral900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.neutral400,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  if (originLabel != null)
                    _MiniChip(
                      label: originLabel,
                      icon: _originIcon(originValue),
                      background: AppColors.neutral100,
                      foreground: AppColors.neutral700,
                    ),
                  if (record.esMockLocation == true)
                    _MiniChip(
                      label: 'Mock GPS',
                      icon: Icons.location_off_outlined,
                      background: AppColors.warningOrange.withValues(alpha: 0.12),
                      foreground: AppColors.warningOrange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _MiniChip({
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
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
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

IconData _originIcon(String origin) {
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

String _originLabel(String origin) {
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

String _shortId(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 8) return trimmed;
  return trimmed.substring(0, 8);
}

