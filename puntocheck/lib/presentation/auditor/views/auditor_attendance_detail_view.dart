import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/auditor_attendance_entry.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/utils/geo/geo_utils.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAttendanceDetailView extends ConsumerStatefulWidget {
  final String recordId;

  const AuditorAttendanceDetailView({super.key, required this.recordId});

  @override
  ConsumerState<AuditorAttendanceDetailView> createState() =>
      _AuditorAttendanceDetailViewState();
}

class _AuditorAttendanceDetailViewState
    extends ConsumerState<AuditorAttendanceDetailView> {
  final _notesCtrl = TextEditingController();
  String? _loadedForId;

  static final DateFormat _dtFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recordId.trim().isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text('Detalle de marca'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.neutral900,
          elevation: 0.5,
        ),
        body: const SafeArea(
          child: Center(
            child: Text('ID de registro inválido.'),
          ),
        ),
      );
    }

    ref.listen(auditorAttendanceNotesControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notas actualizadas')),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar: $e')),
          );
        },
      );
    });

    final entryAsync = ref.watch(auditorAttendanceRecordProvider(widget.recordId));
    final notesCtrlAsync = ref.watch(auditorAttendanceNotesControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Detalle de marca'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: entryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => _ErrorState(
            message: 'No se pudo cargar el registro.\n$e',
            onRetry: () => ref.invalidate(
              auditorAttendanceRecordProvider(widget.recordId),
            ),
          ),
          data: (entry) => _buildContent(context, entry, notesCtrlAsync),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuditorAttendanceEntry entry,
    AsyncValue<void> notesCtrlAsync,
  ) {
    final r = entry.record;
    if (_loadedForId != r.id) {
      _loadedForId = r.id;
      _notesCtrl.text = r.notasSistema ?? '';
    }

    final branch = entry.branch;
    final recPoint = GeoUtils.tryParsePoint(r.ubicacionGps);
    final branchPoint = GeoUtils.tryParsePoint(branch?.ubicacionCentral);
    final double? distance = (recPoint != null && branchPoint != null)
        ? GeoUtils.distanceMeters(recPoint, branchPoint)
        : null;

    final radius = branch?.radioMetros?.toDouble();

    final hasPhoto = r.evidenciaFotoUrl.trim().isNotEmpty;
    final photoUrlAsync =
        hasPhoto ? ref.watch(auditorEvidenceUrlProvider(r.evidenciaFotoUrl)) : null;

    final canSaveNotes = notesCtrlAsync.isLoading == false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Empleado',
          child: _KeyValueTable(
            rows: [
              _RowKV('Nombre', r.perfilNombreCompleto),
              if ((entry.employee?.cedula ?? '').trim().isNotEmpty)
                _RowKV('Cédula', entry.employee!.cedula!.trim()),
            ],
          ),
        ),
        SectionCard(
          title: 'Marca',
          child: _KeyValueTable(
            rows: [
              _RowKV('Tipo', (r.tipoRegistro ?? '—').toString()),
              _RowKV('Fecha/hora', _dtFmt.format(r.fechaHoraMarcacion)),
              if (r.origen != null) _RowKV('Origen', r.origen!.value),
              if (r.ubicacionPrecisionMetros != null)
                _RowKV(
                  'Precisión',
                  '${r.ubicacionPrecisionMetros!.toStringAsFixed(1)} m',
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Sucursal',
          child: _KeyValueTable(
            rows: [
              _RowKV('Nombre', branch?.nombre ?? (r.sucursalNombre ?? 'Sin sucursal')),
              if ((branch?.direccion ?? '').trim().isNotEmpty)
                _RowKV('Dirección', branch!.direccion!.trim()),
              if (radius != null) _RowKV('Radio geocerca', '${radius.toStringAsFixed(0)} m'),
            ],
          ),
        ),
        SectionCard(
          title: 'Geocerca & fraude',
          child: _KeyValueTable(
            rows: [
              _RowKV(
                'Dentro geocerca',
                r.estaDentroGeocerca == null
                    ? '—'
                    : (r.estaDentroGeocerca! ? 'Sí' : 'No'),
              ),
              _RowKV(
                'Mock location',
                r.esMockLocation == true ? 'Sí' : 'No',
              ),
              if (distance != null)
                _RowKV('Distancia al centro', _formatMeters(distance)),
              if (distance != null && radius != null)
                _RowKV(
                  'Comparación',
                  distance <= radius ? 'Dentro del radio' : 'Fuera del radio',
                ),
            ],
          ),
        ),
        if (hasPhoto)
          SectionCard(
            title: 'Evidencia',
            child: photoUrlAsync!.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
              error: (e, _) => _ErrorInline(
                message: 'No se pudo cargar la evidencia.\n$e',
                onRetry: () => ref.invalidate(
                  auditorEvidenceUrlProvider(r.evidenciaFotoUrl),
                ),
              ),
              data: (url) => _EvidencePreview(
                imageUrl: url,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _EvidenceFullScreen(imageUrl: url),
                  ),
                ),
              ),
            ),
          ),
        SectionCard(
          title: 'Notas (auditoría)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notesCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Escribe una nota interna para auditoría...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canSaveNotes
                      ? () => ref
                          .read(auditorAttendanceNotesControllerProvider.notifier)
                          .updateNotes(
                            recordId: r.id,
                            notes: _notesCtrl.text.trim().isEmpty
                                ? null
                                : _notesCtrl.text.trim(),
                          )
                      : null,
                  icon: notesCtrlAsync.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Guardar notas'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatMeters(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }
}

class _EvidencePreview extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _EvidencePreview({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ErrorInline(
              message: 'No se pudo mostrar la imagen.',
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EvidenceFullScreen extends StatelessWidget {
  final String imageUrl;

  const _EvidenceFullScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class _KeyValueTable extends StatelessWidget {
  final List<_RowKV> rows;

  const _KeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _KeyValueRow(label: rows[i].label, value: rows[i].value),
          if (i != rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RowKV {
  final String label;
  final String value;

  const _RowKV(this.label, this.value);
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.errorRed),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorInline extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorInline({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.broken_image_rounded, color: AppColors.neutral700),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ],
    );
  }
}
