import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EmployeeQrScanView extends StatefulWidget {
  const EmployeeQrScanView({super.key});

  @override
  State<EmployeeQrScanView> createState() => _EmployeeQrScanViewState();
}

class _EmployeeQrScanViewState extends State<EmployeeQrScanView>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _handled = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);

    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        controller.stop();
      } catch (_) {
        // ignore
      }
      try {
        controller.dispose();
      } catch (_) {
        // ignore
      }
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      try {
        controller.stop();
      } catch (_) {
        // ignore
      }
      return;
    }

    if (state == AppLifecycleState.resumed && !_handled && !_disposed) {
      try {
        controller.start();
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || _disposed) return;

    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    final code = raw?.trim();
    if (code == null || code.isEmpty) return;

    _handled = true;

    // Detener el stream ANTES de cerrar la pantalla para evitar saturación de buffers.
    try {
      final controller = _controller;
      controller?.stop();
    } catch (_) {
      // ignore: best-effort
    }

    if (!mounted) return;
    Navigator.of(context).pop<String>(code);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (controller != null)
            MobileScanner(controller: controller, onDetect: _onDetect)
          else
            const Center(
              child: Text(
                'No se pudo iniciar el escáner.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () async {
                try {
                  await _controller?.toggleTorch();
                } catch (_) {
                  // ignore
                }
              },
              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 96,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Si el escáner se queda en negro en Xiaomi/MIUI, desactiva el ahorro de batería para PuntoCheck.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
