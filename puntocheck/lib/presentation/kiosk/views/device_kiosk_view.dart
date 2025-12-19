import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/login/views/device_setup_view.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/qr_service.dart';
import 'package:puntocheck/utils/device_identity.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DeviceKioskView extends ConsumerStatefulWidget {
  const DeviceKioskView({super.key});

  @override
  ConsumerState<DeviceKioskView> createState() => _DeviceKioskViewState();
}

class _DeviceKioskViewState extends ConsumerState<DeviceKioskView> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  DeviceIdentity? _identity;
  Sucursales? _branch;

  String? _token;
  DateTime? _expiresAt;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final exp = _expiresAt;
      if (exp == null) return;
      final r = exp.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = r);
      if (r.inSeconds <= 0 && !_refreshing) {
        _refreshQr(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final identity = await getDeviceIdentity();
      final branch = await ref
          .read(organizationServiceProvider)
          .getBranchByAssignedDeviceId(identity.id);

      if (!mounted) return;
      setState(() {
        _identity = identity;
        _branch = branch;
      });

      if (branch == null) {
        setState(() {
          _token = null;
          _expiresAt = null;
          _remaining = Duration.zero;
        });
        return;
      }

      await _refreshQr();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshQr({bool auto = false}) async {
    final branch = _branch;
    if (branch == null) return;

    setState(() {
      _refreshing = true;
      if (!auto) _error = null;
    });

    try {
      if (branch.tieneQrHabilitado != true) {
        throw Exception('QR no habilitado para esta sucursal');
      }

      // Genera un token corto (10 min) para mostrarlo en pantalla.
      final token = await QrService.instance.generateQrForBranch(
        sucursalId: branch.id,
        organizacionId: branch.organizacionId,
        validez: const Duration(minutes: 10),
      );

      if (!mounted) return;
      setState(() {
        _token = token;
        _expiresAt = DateTime.now().add(const Duration(minutes: 10));
        _remaining = _expiresAt!.difference(DateTime.now());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
    final branch = _branch;

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Modo Kiosko'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HeaderCard(identity: identity, branch: branch),
                  const SizedBox(height: 12),
                  if (_error != null) ...[
                    _ErrorCard(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  if (branch == null) ...[
                    _MissingBindingCard(
                      onConfigure: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeviceSetupView(),
                          ),
                        );
                        if (!mounted) return;
                        await _load();
                      },
                    ),
                  ] else ...[
                    _QrCard(
                      token: _token,
                      isRefreshing: _refreshing,
                      remaining: _remaining,
                      onRefresh: _refreshing ? null : () => _refreshQr(),
                    ),
                    const SizedBox(height: 12),
                    const _InstructionsCard(),
                  ],
                ],
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.identity, required this.branch});

  final DeviceIdentity? identity;
  final Sucursales? branch;

  @override
  Widget build(BuildContext context) {
    final deviceId = identity?.id ?? '...';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch != null
                ? 'Sucursal: ${branch!.nombre}'
                : 'Sucursal: No vinculada',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Device ID: $deviceId',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.neutral700,
            ),
          ),
          if (identity != null) ...[
            const SizedBox(height: 6),
            Text(
              'Equipo: ${identity!.model} (${identity!.platform})',
              style: const TextStyle(color: AppColors.neutral600),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.token,
    required this.isRefreshing,
    required this.remaining,
    required this.onRefresh,
  });

  final String? token;
  final bool isRefreshing;
  final Duration remaining;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final remainingText = remaining.inSeconds <= 0
        ? 'Expirado'
        : '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'QR de asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
              const Spacer(),
              Text(
                remainingText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: remaining.inSeconds <= 30
                      ? AppColors.errorRed
                      : AppColors.neutral700,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refrescar QR',
                onPressed: onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (token == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Generando QR...'),
            )
          else
            Center(
              child: QrImageView(
                data: token!,
                size: 280,
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingBindingCard extends StatelessWidget {
  const _MissingBindingCard({required this.onConfigure});

  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Este dispositivo no esta vinculado a una sucursal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1) Configura un Device ID.\n'
            '2) En el panel admin, pega ese ID en la sucursal (device_id_qr_asignado).\n'
            '3) Activa QR en la sucursal.',
            style: TextStyle(color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onConfigure,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.settings, color: Colors.white),
            label: const Text('Configurar Device ID'),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: const Text(
        'El empleado abre PuntoCheck en su celular, entra a "Marcar asistencia" y escanea este QR.\n\n'
        'El QR expira cada 10 minutos. Puedes refrescarlo manualmente.',
        style: TextStyle(color: AppColors.neutral700),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
