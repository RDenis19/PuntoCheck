import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/device_identity.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminNewBranchView extends ConsumerStatefulWidget {
  const OrgAdminNewBranchView({super.key});

  @override
  ConsumerState<OrgAdminNewBranchView> createState() =>
      _OrgAdminNewBranchViewState();
}

class _OrgAdminNewBranchViewState extends ConsumerState<OrgAdminNewBranchView> {
  bool _isSaving = false;
  bool _sheetVisible = true;
  LatLng _selectedLatLng = const LatLng(-4.0033, -79.2030);
  double _radius = 100;
  bool _qrEnabled = false;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _deviceIdCtrl = TextEditingController();
  bool _loadingDeviceId = false;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _deviceIdCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva sucursal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ref
            .watch(orgAdminOrganizationProvider)
            .when(
              data: (org) {
                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLatLng,
                        zoom: 16,
                      ),
                      onMapCreated: (c) => _mapController = c,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onTap: (latLng) {
                        setState(() {
                          _selectedLatLng = latLng;
                        });
                      },
                      circles: {
                        Circle(
                          circleId: const CircleId('geofence'),
                          center: _selectedLatLng,
                          radius: _radius,
                          strokeColor: AppColors.primaryRed.withValues(
                            alpha: 0.45,
                          ),
                          fillColor: AppColors.primaryRed.withValues(
                            alpha: 0.16,
                          ),
                          strokeWidth: 2,
                        ),
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('branch_pin'),
                          position: _selectedLatLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                    ),
                    // Indicador de toque
                    // Lat/Lon chips
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: _CoordBadge(
                              label: 'Latitud',
                              value: _selectedLatLng.latitude.toStringAsFixed(
                                6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CoordBadge(
                              label: 'Longitud',
                              value: _selectedLatLng.longitude.toStringAsFixed(
                                6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom sheet form
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _sheetVisible
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 12,
                                      offset: Offset(0, -4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                child: SafeArea(
                                  top: false,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                    ),
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            12,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: AppColors.neutral300,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: () => setState(
                                                  () => _sheetVisible = false,
                                                ),
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Nueva sucursal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              color: AppColors.neutral900,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Radio de geocerca',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.neutral900,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Slider(
                                                  value: _radius,
                                                  min: 20,
                                                  max: 500,
                                                  divisions: 24,
                                                  activeColor:
                                                      AppColors.primaryRed,
                                                  onChanged: (v) {
                                                    setState(() => _radius = v);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_radius.toInt()} m',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.neutral900,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Detalles',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.neutral900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _nameCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Nombre',
                                              prefixIcon: Icon(
                                                Icons
                                                    .store_mall_directory_outlined,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _addressCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Direccion',
                                              prefixIcon: Icon(
                                                Icons.place_outlined,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('Habilitar QR'),
                                            value: _qrEnabled,
                                            onChanged: (v) =>
                                                setState(() => _qrEnabled = v),
                                          ),
                                          if (_qrEnabled) ...[
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: _deviceIdCtrl,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Device ID (PuntoCheck) asignado (opcional)',
                                                prefixIcon: Icon(
                                                  Icons.phone_android_outlined,
                                                ),
                                                helperText:
                                                    'Es un ID generado por la app (no es IMEI). Deja vacio si no deseas amarrar el QR fijo a un dispositivo.',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed:
                                                        _isSaving ||
                                                            _loadingDeviceId
                                                        ? null
                                                        : _fillWithMyDeviceId,
                                                    icon: _loadingDeviceId
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : const Icon(
                                                            Icons
                                                                .smartphone_outlined,
                                                          ),
                                                    label: const Text(
                                                      'Usar mi Device ID',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                IconButton(
                                                  tooltip: 'Copiar',
                                                  onPressed:
                                                      _deviceIdCtrl.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : () async {
                                                          await Clipboard.setData(
                                                            ClipboardData(
                                                              text:
                                                                  _deviceIdCtrl
                                                                      .text
                                                                      .trim(),
                                                            ),
                                                          );
                                                          if (!mounted) return;
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Device ID copiado',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  icon: const Icon(
                                                    Icons.copy_rounded,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: _isSaving
                                                      ? null
                                                      : () => Navigator.of(
                                                          context,
                                                        ).maybePop(false),
                                                  child: const Text('Cancelar'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.save,
                                                    color: Colors.white,
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryRed,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: _isSaving
                                                      ? null
                                                      : () => _save(org.id),
                                                  label: Text(
                                                    _isSaving
                                                        ? 'Guardando...'
                                                        : 'Guardar',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.keyboard_arrow_up,
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () =>
                                      setState(() => _sheetVisible = true),
                                  label: const Text('Mostrar formulario'),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _NewBranchError(
                message: '$e',
                onRetry: () => ref.invalidate(orgAdminOrganizationProvider),
              ),
            ),
      ),
    );
  }

  Future<void> _save(String orgId) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El nombre es requerido')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final deviceId = _deviceIdCtrl.text.trim().isEmpty
          ? null
          : _deviceIdCtrl.text.trim();
      final sucursal = Sucursales(
        id: '',
        organizacionId: orgId,
        nombre: _nameCtrl.text.trim(),
        direccion: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        radioMetros: _radius.toInt(),
        tieneQrHabilitado: _qrEnabled,
        deviceIdQrAsignado: _qrEnabled ? deviceId : null,
        ubicacionCentral: {
          'type': 'Point',
          'coordinates': [_selectedLatLng.longitude, _selectedLatLng.latitude],
        },
      );

      await ref
          .read(orgAdminBranchMutationControllerProvider.notifier)
          .create(sucursal);
      final state = ref.read(orgAdminBranchMutationControllerProvider);
      if (state.hasError) throw state.error!;
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final friendly = msg.contains('No tienes permisos')
          ? 'No tienes permisos para crear sucursales. Revisa las policies RLS.'
          : msg;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _fillWithMyDeviceId() async {
    setState(() => _loadingDeviceId = true);
    try {
      final identity = await getDeviceIdentity();
      if (!mounted) return;
      setState(() => _deviceIdCtrl.text = identity.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Detectado: ${identity.model}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener Device ID: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDeviceId = false);
    }
  }
}

class _CoordBadge extends StatelessWidget {
  final String label;
  final String value;

  const _CoordBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewBranchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NewBranchError({required this.message, required this.onRetry});

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
              size: 42,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
