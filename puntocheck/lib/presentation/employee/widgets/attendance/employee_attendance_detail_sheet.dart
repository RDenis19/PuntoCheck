import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/employee/widgets/attendance/employee_attendance_style.dart';
import 'package:puntocheck/services/storage_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeAttendanceDetailSheet extends StatelessWidget {
  const EmployeeAttendanceDetailSheet({
    super.key,
    required this.record,
    required this.timeFmt,
  });

  final RegistrosAsistencia record;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final style = attendanceTypeStyle(record.tipoRegistro ?? '');

    final branch = (record.sucursalNombre ?? '').trim();
    final branchLabel =
        branch.isNotEmpty ? branch : (record.sucursalId != null ? _shortId(record.sucursalId!) : '—');

    final geo = record.estaDentroGeocerca;
    final geoLabel = geo == null ? '—' : (geo ? 'Dentro de geocerca' : 'Fuera de geocerca');
    final geoColor = geo == null
        ? AppColors.neutral500
        : (geo ? AppColors.successGreen : AppColors.errorRed);

    final originLabel = (record.origen?.value ?? '').trim();
    final origin = originLabel.isEmpty ? '—' : originLabel;

    final precision = record.ubicacionPrecisionMetros;
    final precisionLabel = precision == null ? '—' : '${precision.toStringAsFixed(0)} m';

    final mock = record.esMockLocation;
    final mockLabel = mock == null ? '—' : (mock ? 'Sí' : 'No');
    final mockColor = mock == null
        ? AppColors.neutral500
        : (mock ? AppColors.warningOrange : AppColors.successGreen);

    final evidencia = record.evidenciaFotoUrl.trim();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Detalle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: style.color.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon, color: style.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dateFmt.format(record.fechaHoraMarcacion)} • ${timeFmt.format(record.fechaHoraMarcacion)}',
                              style: const TextStyle(color: AppColors.neutral700),
                            ),
                          ],
                        ),
                      ),
                      _Pill(label: geoLabel, color: geoColor),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'Sucursal', value: branchLabel),
                _DetailRow(label: 'Origen', value: origin),
                _DetailRow(label: 'Precisión', value: precisionLabel),
                _DetailRow(
                  label: 'Mock location',
                  value: mockLabel,
                  valueColor: mockColor,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: evidencia.isEmpty
                        ? null
                        : () => _openEvidence(context, evidencia),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Ver evidencia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEvidence(BuildContext context, String evidence) {
    showDialog<void>(
      context: context,
      builder: (_) => _EvidenceDialog(evidence: evidence),
    );
  }
}

class _EvidenceDialog extends StatelessWidget {
  final String evidence;
  const _EvidenceDialog({required this.evidence});

  bool get _isUrl =>
      evidence.startsWith('http://') || evidence.startsWith('https://');

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
              child: _isUrl
                  ? Image.network(evidence, fit: BoxFit.cover)
                  : FutureBuilder<String>(
                      future: StorageService.instance.getSignedUrl(
                        'evidencias',
                        evidence,
                        expiresIn: 60 * 5,
                      ),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryRed,
                            ),
                          );
                        }
                        final url = (snap.data ?? '').trim();
                        if (url.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No se pudo generar URL.\nPath: $evidence',
                                style: const TextStyle(color: AppColors.neutral700),
                              ),
                            ),
                          );
                        }
                        return Image.network(url, fit: BoxFit.cover);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
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
              style: TextStyle(color: valueColor ?? AppColors.neutral900),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

