import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/qr_codigos_temporales.dart';
import 'package:puntocheck/services/qr_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';

class OrgAdminBranchQrView extends ConsumerStatefulWidget {
  final Sucursales branch;

  const OrgAdminBranchQrView({super.key, required this.branch});

  @override
  ConsumerState<OrgAdminBranchQrView> createState() =>
      _OrgAdminBranchQrViewState();
}

class _OrgAdminBranchQrViewState extends ConsumerState<OrgAdminBranchQrView> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isGenerating = false;
  String? _currentToken;

  @override
  Widget build(BuildContext context) {
    final qrAsync = ref.watch(_qrProvider(widget.branch.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: qrAsync.when(
          data: (qr) {
            final token = _currentToken ?? widget.branch.id;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info de sucursal
                  _BranchInfoCard(branch: widget.branch),
                  const SizedBox(height: 16),

                  // QR Code
                  _QrCodeCard(qrKey: _qrKey, token: token, qrData: qr),
                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isGenerating
                              ? null
                              : _regenerateQr,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadQr,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.download),
                          label: const Text('Descargar'),
                        ),
                      ),
                    ],
                  ),

                  // Info del QR actual
                  if (qr != null) ...[
                    const SizedBox(height: 16),
                    _QrInfoCard(qr: qr),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(_qrProvider(widget.branch.id)),
          ),
        ),
      ),
    );
  }

  Future<void> _regenerateQr() async {
    setState(() => _isGenerating = true);
    try {
      final newToken = await QrService.instance.generateQrForBranch(
        sucursalId: widget.branch.id,
        organizacionId: widget.branch.organizacionId,
      );

      setState(() => _currentToken = newToken);
      ref.invalidate(_qrProvider(widget.branch.id));

      if (!mounted) return;
      showAppSnackBar(context, 'QR regenerado exitosamente');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadQr() async {
    try {
      showAppSnackBar(context, 'Descargando QR...');

      // Capturar QR como imagen
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('No se pudo capturar el QR');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Guardar en directorio de descargas
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/QR_${widget.branch.nombre}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      showAppSnackBar(context, 'QR guardado en: $filePath');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error descargando: $e', success: false);
    }
  }
}

// ============================================================================
// Provider
// ============================================================================
final _qrProvider = FutureProvider.family<QrCodigosTemporales?, String>((
  ref,
  sucursalId,
) async {
  return QrService.instance.getActiveQrMetadata(sucursalId);
});

// ============================================================================
// Widgets
// ============================================================================
class _BranchInfoCard extends StatelessWidget {
  final Sucursales branch;

  const _BranchInfoCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          if (branch.direccion != null) ...[
            const SizedBox(height: 8),
            Text(
              branch.direccion!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrCodeCard extends StatelessWidget {
  final GlobalKey qrKey;
  final String token;
  final QrCodigosTemporales? qrData;

  const _QrCodeCard({required this.qrKey, required this.token, this.qrData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          RepaintBoundary(
            key: qrKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Código: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.neutral600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QrInfoCard extends StatelessWidget {
  final QrCodigosTemporales qr;

  const _QrInfoCard({required this.qr});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diasRestantes = qr.fechaExpiracion.difference(now).inDays;
    final estaVencido = diasRestantes < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estaVencido ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaVencido ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                estaVencido ? Icons.error_outline : Icons.check_circle_outline,
                color: estaVencido
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                estaVencido ? 'QR Vencido' : 'QR Activo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: estaVencido
                      ? Colors.red.shade900
                      : Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Expira', value: _formatDate(qr.fechaExpiracion)),
          _InfoRow(
            label: 'Días restantes',
            value: estaVencido
                ? 'Vencido hace ${diasRestantes.abs()} días'
                : '$diasRestantes días',
          ),
          if (qr.creadoEn != null)
            _InfoRow(label: 'Creado', value: _formatDate(qr.creadoEn!)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.neutral700, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error cargando QR',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
