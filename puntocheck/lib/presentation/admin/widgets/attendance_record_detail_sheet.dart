import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/admin/widgets/geofence_badge.dart';
import 'package:puntocheck/presentation/admin/widgets/type_badge.dart';
import 'package:puntocheck/presentation/shared/widgets/storage_object_image.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AdminAttendanceRecordDetailSheet extends StatelessWidget {
  const AdminAttendanceRecordDetailSheet({
    super.key,
    required this.record,
  });

  final RegistrosAsistencia record;

  @override
  Widget build(BuildContext context) {
    final dtFmt = DateFormat('dd/MM/yyyy HH:mm');
    final employeeName = record.perfilNombreCompleto;

    final branch = (record.sucursalNombre ?? '').trim();
    final branchLabel = branch.isNotEmpty
        ? branch
        : (record.sucursalId == null ? 'Sin sucursal' : _shortId(record.sucursalId!));

    final origin = (record.origen?.value ?? '').trim();
    final originLabel = origin.isEmpty ? '—' : origin;

    final precision = record.ubicacionPrecisionMetros;
    final precisionLabel = precision == null ? '—' : '${precision.toStringAsFixed(1)} m';

    final geo = record.estaDentroGeocerca;
    final mock = record.esMockLocation;

    final coords = _formatLatLon(record.ubicacionGps);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle de marcación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employeeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                branchLabel,
                                style: const TextStyle(
                                  color: AppColors.neutral700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dtFmt.format(record.fechaHoraMarcacion),
                                style: const TextStyle(color: AppColors.neutral700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TypeBadge(type: record.tipoRegistro, compact: true),
                            const SizedBox(height: 8),
                            GeofenceBadge(
                              isInside: record.estaDentroGeocerca,
                              precisionMeters: record.ubicacionPrecisionMetros,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (mock == true) ...[
                      const SizedBox(height: 10),
                      _Pill(
                        label: 'Posible Mock GPS',
                        icon: Icons.location_off_outlined,
                        color: AppColors.warningOrange,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Información',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 10),
              _DetailRow(label: 'Origen', value: originLabel),
              _DetailRow(label: 'Precisión', value: precisionLabel),
              _DetailRow(
                label: 'Geocerca',
                value: geo == null ? '—' : (geo ? 'Dentro' : 'Fuera'),
                valueColor: geo == null
                    ? AppColors.neutral700
                    : (geo ? AppColors.successGreen : AppColors.warningOrange),
              ),
              _DetailRow(
                label: 'Mock location',
                value: mock == null ? '—' : (mock ? 'Sí' : 'No'),
                valueColor: mock == null
                    ? AppColors.neutral700
                    : (mock ? AppColors.warningOrange : AppColors.successGreen),
              ),
              if (coords != null) _DetailRow(label: 'Ubicación', value: coords),
              _DetailRow(label: 'ID', value: _shortId(record.id)),
              const SizedBox(height: 16),
              const Text(
                'Evidencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: record.evidenciaFotoUrl.trim().isEmpty
                      ? null
                      : () => _openEvidence(context, record.evidenciaFotoUrl),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Ver evidencia'),
                ),
              ),
              if ((record.notasSistema ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Text(
                    record.notasSistema!.trim(),
                    style: const TextStyle(color: AppColors.neutral900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openEvidence(BuildContext context, String pathOrUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => _EvidenceDialog(pathOrUrl: pathOrUrl),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceDialog extends StatelessWidget {
  const _EvidenceDialog({required this.pathOrUrl});

  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Evidencia',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StorageObjectImage(
                  bucketId: 'evidencias',
                  pathOrUrl: pathOrUrl,
                  fit: BoxFit.cover,
                  signedUrlExpiresInSeconds: 60 * 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

String _shortId(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 8) return trimmed;
  return trimmed.substring(0, 8);
}

String? _formatLatLon(Map<String, dynamic>? geoJsonPoint) {
  if (geoJsonPoint == null) return null;
  final coords = geoJsonPoint['coordinates'];
  if (coords is List && coords.length == 2) {
    final lon = coords[0];
    final lat = coords[1];
    if (lon is num && lat is num) {
      return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    }
  }
  return null;
}
