import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/presentation/employee/views/employee_attendance_map_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_qr_scan_view.dart';
import 'package:puntocheck/services/attendance_helper.dart';
import 'package:puntocheck/utils/safe_image_picker.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeMarkAttendanceView extends ConsumerStatefulWidget {
  final String actionType; // 'entrada' o 'salida'

  const EmployeeMarkAttendanceView({super.key, required this.actionType});

  @override
  ConsumerState<EmployeeMarkAttendanceView> createState() =>
      _EmployeeMarkAttendanceViewState();
}

enum _AttendanceMode { gps, qr }

class _EmployeeMarkAttendanceViewState
    extends ConsumerState<EmployeeMarkAttendanceView> {
  final _imagePicker = SafeImagePicker();
  final _fallbackPicker = ImagePicker();

  _AttendanceMode _mode = _AttendanceMode.gps;
  late String _selectedType;
  CameraDevice _cameraDevice = CameraDevice.front;
  bool _suspendPlatformViews = false;

  // Evidence
  File? _evidencePhoto;

  // GPS
  bool _isLocating = false;
  Position? _position;
  _BranchMatch? _branchMatch;
  String? _locationError;

  // QR
  String? _qrRaw;
  Map<String, String>? _qrInfo;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.actionType;
    _refreshLocation();
  }

  @override
  Widget build(BuildContext context) {
    final lastAttendance = ref.watch(lastAttendanceProvider).valueOrNull;
    final schedule = ref.watch(employeeScheduleProvider).valueOrNull;
    final legalCfg =
        ref.watch(employeeLegalConfigProvider).valueOrNull ?? const <String, dynamic>{};
    final controllerState = ref.watch(employeeAttendanceControllerProvider);

    final breakMin = _asInt(legalCfg['tiempo_descanso_min']) ?? 60;

    final allowedTypes = AttendanceHelper.getAllowedTypes(
      lastAttendance,
      DateTime.now(),
    );

    if (!allowedTypes.contains(_selectedType) && allowedTypes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedType = allowedTypes.first);
      });
    }

    final isSubmitting = controllerState.isLoading;
    final canSubmit = !isSubmitting &&
        _evidencePhoto != null &&
        (_mode == _AttendanceMode.qr ? _qrInfo != null : _position != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcar asistencia'),
        backgroundColor: AppColors.primaryRed,
        surfaceTintColor: AppColors.primaryRed,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Tipo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in allowedTypes)
                ChoiceChip(
                  label: Text(AttendanceHelper.getTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                ),
            ],
          ),
          if (allowedTypes.contains('inicio_break') ||
              allowedTypes.contains('fin_break')) ...[
            const SizedBox(height: 14),
            _BreakQuickActions(
              breakMin: breakMin,
              lastAttendance: lastAttendance,
              canStart: allowedTypes.contains('inicio_break'),
              canEnd: allowedTypes.contains('fin_break'),
              onStart: allowedTypes.contains('inicio_break')
                  ? () => setState(() => _selectedType = 'inicio_break')
                  : null,
              onEnd: allowedTypes.contains('fin_break')
                  ? () => setState(() => _selectedType = 'fin_break')
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle('Modo'),
          const SizedBox(height: 8),
          _ModeToggle(
            mode: _mode,
            onChanged: (next) {
              setState(() {
                _mode = next;
                _locationError = null;
              });
              if (next == _AttendanceMode.gps && _position == null) {
                _refreshLocation();
              }
            },
          ),
          const SizedBox(height: 16),
          if (_mode == _AttendanceMode.gps) ...[
            _SectionTitle('Ubicación'),
            const SizedBox(height: 8),
            _LocationCard(
              isLocating: _isLocating,
              error: _locationError,
              position: _position,
              branchMatch: _branchMatch,
              onRefresh: isSubmitting ? null : _refreshLocation,
              onOpenSettings: () async {
                await Geolocator.openAppSettings();
              },
            ),
            const SizedBox(height: 12),
            _MapPreviewCard(
              suspendPlatformViews: _suspendPlatformViews,
              position: _position,
              branchMatch: _branchMatch,
              onOpenFullMap: _openFullMap,
            ),
          ] else ...[
            _SectionTitle('QR'),
            const SizedBox(height: 8),
            _QrCard(
              qrInfo: _qrInfo,
              raw: _qrRaw,
              isSubmitting: isSubmitting,
              onScan: _scanQr,
              onClear: () => setState(() {
                _qrRaw = null;
                _qrInfo = null;
              }),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle('Evidencia (foto)'),
          const SizedBox(height: 8),
          _EvidenceCard(
            photo: _evidencePhoto,
            isSubmitting: isSubmitting,
            cameraDevice: _cameraDevice,
            onCameraDeviceChanged: (d) => setState(() => _cameraDevice = d),
            onTakePhoto: _takePhoto,
            onRemove: () => setState(() => _evidencePhoto = null),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit
                ? () => _submit(
                      lastAttendance: lastAttendance,
                      toleranceMinutes:
                          schedule?.plantilla.toleranciaEntradaMinutos ??
                          _asInt(legalCfg['tolerancia_entrada_min']) ??
                          15,
                      breakMin: breakMin,
                    )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _colorForType(_selectedType),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Registrar ${AttendanceHelper.getTypeLabel(_selectedType)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            canSubmit
                ? 'Listo para registrar.'
                : _hintText(isSubmitting: isSubmitting),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _hintText({required bool isSubmitting}) {
    if (isSubmitting) return 'Registrando...';
    if (_evidencePhoto == null) return 'Toma una foto para habilitar el botón.';
    if (_mode == _AttendanceMode.qr) {
      return _qrInfo == null ? 'Escanea el QR de la sucursal.' : 'Confirma.';
    }
    return _position == null ? 'Obtén tu ubicación (GPS) para continuar.' : 'Confirma.';
  }

  Future<void> _takePhoto() async {
    // Mitigación MIUI/Adreno: suspender PlatformViews (GoogleMap) antes de abrir cámara.
    if (mounted) setState(() => _suspendPlatformViews = true);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    SafeImagePickerResult? lastResult;

    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: _cameraDevice,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 55,
      );
      lastResult = result;

      if (!mounted) return;

      if (result.permanentlyDenied) {
        _showError('Permiso de cámara denegado permanentemente. Actívalo en Ajustes.');
        return;
      }

      if (result.permissionDenied) {
        _showError('Permiso de cámara denegado.');
        return;
      }

      File? file = result.file ?? await _imagePicker.recoverLostImage();

      if (!mounted) return;

      if (file == null) {
        // Fallback único: usar ImagePicker directo (sin wrapper) para evitar casos donde
        // algunos OEMs devuelven null sin excepción.
        try {
          final picked = await _fallbackPicker.pickImage(
            source: ImageSource.camera,
            imageQuality: 55,
            maxWidth: 1280,
            maxHeight: 1280,
          );
          if (!mounted) return;
          if (picked != null) {
            file = await _persistPickedToTemp(picked);
          }
        } catch (e) {
          if (!mounted) return;
          _showError('No se pudo abrir la cámara: $e');
          return;
        }
      }

      if (!mounted) return;

      if (file == null) {
        final msg = (lastResult.errorMessage ?? '').trim();
        final hint = _cameraDevice == CameraDevice.front
            ? ' Prueba cambiando a cámara trasera.'
            : ' Prueba cambiando a cámara frontal.';
        _showError(
          msg.isEmpty ? 'Captura cancelada.$hint' : 'No se pudo abrir la cámara: $msg',
        );
        return;
      }

      setState(() => _evidencePhoto = file);
    } finally {
      if (mounted) setState(() => _suspendPlatformViews = false);
    }
  }

  Future<File> _persistPickedToTemp(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) throw Exception('La imagen capturada está vacía.');
    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  void _openFullMap() {
    final pos = _position;
    final match = _branchMatch;
    if (pos == null || match == null) return;
    final coords = _extractLatLng(match.branch);
    if (coords == null) return;

    final user = LatLng(pos.latitude, pos.longitude);
    final branch = LatLng(coords.$1, coords.$2);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeAttendanceMapView(
          user: user,
          branch: branch,
          radiusMeters: match.radiusMeters,
          branchName: match.branch.nombre,
          branchAddress: match.branch.direccion,
          insideGeofence: match.isInside,
        ),
      ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Activa el GPS para marcar asistencia.');
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
          'Permiso de ubicación denegado permanentemente. Actívalo en Ajustes.',
        );
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _position = lastKnown);
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final branches = await ref.read(employeeBranchesProvider.future);
      final match = _computeNearestBranch(pos, branches);

      if (!mounted) return;
      setState(() {
        _position = pos;
        _branchMatch = match;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  _BranchMatch? _computeNearestBranch(Position pos, List<Sucursales> branches) {
    _BranchMatch? best;
    for (final b in branches) {
      final coords = _extractLatLng(b);
      if (coords == null) continue;
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        coords.$1,
        coords.$2,
      );
      if (best == null || dist < best.distanceMeters) {
        best = _BranchMatch(branch: b, distanceMeters: dist);
      }
    }
    return best;
  }

  (double, double)? _extractLatLng(Sucursales branch) {
    final geo = branch.ubicacionCentral;
    if (geo == null) return null;

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
      return null;
    }

    final coords = geo['coordinates'];
    if (coords is List && coords.length == 2) {
      final lon = toDouble(coords[0]);
      final lat = toDouble(coords[1]);
      if (lat != null && lon != null) return (lat, lon);
    }

    final lon = toDouble(geo['lon'] ?? geo['lng'] ?? geo['longitude']);
    final lat = toDouble(geo['lat'] ?? geo['latitude']);
    if (lat != null && lon != null) return (lat, lon);

    return null;
  }

  Future<void> _scanQr() async {
    try {
      final raw = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const EmployeeQrScanView()),
      );
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isEmpty) return;

      final controller = ref.read(employeeAttendanceControllerProvider.notifier);
      final info = await controller.validateQr(trimmed);

      if (!mounted) return;
      setState(() {
        _qrRaw = trimmed;
        _qrInfo = info;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('$e');
    }
  }

  Future<void> _submit({
    required RegistrosAsistencia? lastAttendance,
    required int toleranceMinutes,
    required int breakMin,
  }) async {
    final now = DateTime.now();

    final validation = AttendanceHelper.validateRegistroType(
      _selectedType,
      lastAttendance,
      now,
    );
    if (!validation.isValid) {
      _showError(validation.errorMessage ?? 'Tipo de registro no permitido.');
      return;
    }

    if (_evidencePhoto == null) {
      _showError('Debes tomar una foto para registrar la asistencia.');
      return;
    }

    if (_mode == _AttendanceMode.gps && _position == null) {
      _showError('No se pudo obtener tu ubicación. Activa GPS y reintenta.');
      return;
    }

    if (_mode == _AttendanceMode.qr && _qrInfo == null) {
      _showError('Escanea el QR de la sucursal.');
      return;
    }

    if (_selectedType == 'fin_break' &&
        breakMin > 0 &&
        lastAttendance?.tipoRegistro == 'inicio_break' &&
        lastAttendance?.fechaHoraMarcacion != null &&
        AttendanceHelper.isSameDay(lastAttendance!.fechaHoraMarcacion, now)) {
      final elapsed = now.difference(lastAttendance.fechaHoraMarcacion);
      final minDur = Duration(minutes: breakMin);
      if (elapsed < minDur) {
        final proceed = await _confirmEarlyBreakEnd(
          context,
          elapsed: elapsed,
          minDuration: minDur,
        );
        if (!mounted) return;
        if (!proceed) return;
      }
    }

    if (_mode == _AttendanceMode.gps && _selectedType == 'entrada') {
      final schedule = ref.read(employeeScheduleProvider).valueOrNull;
      final latestEntry = AttendanceHelper.computeLatestEntryTime(
        schedule?.plantilla,
        toleranceMinutes,
      );
      if (latestEntry != null && now.isAfter(latestEntry)) {
        if (!mounted) return;
        _showError(
          'Tolerancia vencida. Límite: ${TimeOfDay.fromDateTime(latestEntry).format(context)}',
        );
        return;
      }
    }

    final controller = ref.read(employeeAttendanceControllerProvider.notifier);

    try {
      final pos = _position;
      final match = _branchMatch;
      final inside = match?.isInside ?? false;
      final sucursalIdQr = _qrInfo == null ? null : _qrInfo!['sucursal_id'];
      final sucursalIdGps = match?.branch.id;

      final result = await controller.registerAttendance(
        tipoRegistro: _selectedType,
        isQr: _mode == _AttendanceMode.qr,
        latitud: _mode == _AttendanceMode.gps ? pos?.latitude : null,
        longitud: _mode == _AttendanceMode.gps ? pos?.longitude : null,
        sucursalId: _mode == _AttendanceMode.qr ? sucursalIdQr : sucursalIdGps,
        estaDentroGeocerca: _mode == _AttendanceMode.qr ? true : inside,
        notas: _mode == _AttendanceMode.qr ? 'Validado por QR' : 'Registro GPS',
        evidenciaPhoto: _evidencePhoto,
        precisionMetros: _mode == _AttendanceMode.gps ? pos?.accuracy : null,
        esMockLocation: _mode == _AttendanceMode.gps ? (pos?.isMocked ?? false) : false,
      );

      final state = ref.read(employeeAttendanceControllerProvider);
      if (state.hasError) throw state.error ?? Exception('Error desconocido');

      if (!mounted) return;

      final zone = _mode == _AttendanceMode.qr
          ? 'QR'
          : (inside ? 'EN ZONA' : 'FUERA DE ZONA');
      final msg = result == null
          ? 'Marcación registrada ($zone).'
          : 'Marcación registrada ($zone).';

      _showSuccess(msg);
      setState(() {
        _evidencePhoto = null;
        _selectedType = AttendanceHelper.getNextType(_selectedType);
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    }
  }

  Future<bool> _confirmEarlyBreakEnd(
    BuildContext context, {
    required Duration elapsed,
    required Duration minDuration,
  }) async {
    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds.remainder(60);
      return '${m}m ${s}s';
    }

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descanso muy corto'),
        content: Text(
          'Llevas ${fmt(elapsed)} de descanso, pero el mínimo recomendado es ${fmt(minDuration)}. ¿Quieres terminar igual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );

    return res ?? false;
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'entrada':
        return AppColors.successGreen;
      case 'salida':
        return AppColors.primaryRed;
      case 'inicio_break':
      case 'fin_break':
        return AppColors.warningOrange;
      default:
        return AppColors.neutral700;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.successGreen),
    );
  }
}

class _BranchMatch {
  _BranchMatch({required this.branch, required this.distanceMeters});

  final Sucursales branch;
  final double distanceMeters;

  int get radiusMeters => branch.radioMetros ?? 50;

  bool get isInside => distanceMeters <= radiusMeters;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.neutral900,
          ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _AttendanceMode mode;
  final ValueChanged<_AttendanceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = mode == _AttendanceMode.gps ? 0 : 1;
    return ToggleButtons(
      isSelected: [selected == 0, selected == 1],
      onPressed: (i) => onChanged(i == 0 ? _AttendanceMode.gps : _AttendanceMode.qr),
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.white,
      fillColor: AppColors.primaryRed,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [Icon(Icons.my_location_rounded, size: 18), SizedBox(width: 8), Text('GPS')]),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [Icon(Icons.qr_code_scanner_rounded, size: 18), SizedBox(width: 8), Text('QR')]),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.isLocating,
    required this.error,
    required this.position,
    required this.branchMatch,
    required this.onRefresh,
    required this.onOpenSettings,
  });

  final bool isLocating;
  final String? error;
  final Position? position;
  final _BranchMatch? branchMatch;
  final VoidCallback? onRefresh;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    final match = branchMatch;

    final statusText = () {
      if (isLocating) return 'Localizando...';
      if (error != null) return error!;
      if (pos == null) return 'Sin ubicación';
      return 'OK';
    }();

    final statusColor = () {
      if (isLocating) return AppColors.neutral600;
      if (error != null) return AppColors.errorRed;
      if (pos == null) return AppColors.warningOrange;
      return AppColors.successGreen;
    }();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (pos != null) ...[
              const SizedBox(height: 8),
              Text(
                'Precisión: ${pos.accuracy.toStringAsFixed(0)}m',
                style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
              ),
            ],
            if (match != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    match.isInside ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: match.isInside ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${match.branch.nombre} • ${match.distanceMeters.toStringAsFixed(0)}m (radio ${match.radiusMeters}m)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
            if (error != null && error!.contains('Ajustes')) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Abrir ajustes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.qrInfo,
    required this.raw,
    required this.isSubmitting,
    required this.onScan,
    required this.onClear,
  });

  final Map<String, String>? qrInfo;
  final String? raw;
  final bool isSubmitting;
  final VoidCallback onScan;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final info = qrInfo;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info == null) ...[
              const Text(
                'Escanea el QR de la sucursal para registrar sin GPS.',
                style: TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear QR'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
                ),
              ),
            ] else ...[
              Text(
                'Sucursal: ${info['sucursal_id']}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                raw ?? '',
                style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onClear,
                  icon: const Icon(Icons.close),
                  label: const Text('Escanear otro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.photo,
    required this.isSubmitting,
    required this.cameraDevice,
    required this.onCameraDeviceChanged,
    required this.onTakePhoto,
    required this.onRemove,
  });

  final File? photo;
  final bool isSubmitting;
  final CameraDevice cameraDevice;
  final ValueChanged<CameraDevice> onCameraDeviceChanged;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<CameraDevice>(
                    segments: const [
                      ButtonSegment(
                        value: CameraDevice.front,
                        label: Text('Selfie'),
                        icon: Icon(Icons.face),
                      ),
                      ButtonSegment(
                        value: CameraDevice.rear,
                        label: Text('Trasera'),
                        icon: Icon(Icons.photo_camera_back),
                      ),
                    ],
                    selected: {cameraDevice},
                    onSelectionChanged: (set) {
                      final v = set.isEmpty ? CameraDevice.front : set.first;
                      onCameraDeviceChanged(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasPhoto) ...[
              const Text(
                'Toma una selfie (evidencia). Se sube a Supabase al confirmar.',
                style: TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onTakePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Tomar foto'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryRed),
                ),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  photo!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : onTakePhoto,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Repetir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Quitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: BorderSide(color: AppColors.neutral300),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.suspendPlatformViews,
    required this.position,
    required this.branchMatch,
    required this.onOpenFullMap,
  });

  final bool suspendPlatformViews;
  final Position? position;
  final _BranchMatch? branchMatch;
  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    final match = branchMatch;
    if (pos == null || match == null) {
      return const SizedBox.shrink();
    }

    if (suspendPlatformViews) {
      return _MapPlaceholder(onOpenFullMap: onOpenFullMap);
    }

    final coords = match.branch.ubicacionCentral;
    if (coords == null) {
      return _MapPlaceholder(onOpenFullMap: onOpenFullMap);
    }

    // Extraer (lat, lon) del GeoJSON con el mismo criterio que el state.
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
      return null;
    }

    (double, double)? extractLatLng() {
      final c = coords['coordinates'];
      if (c is List && c.length == 2) {
        final lon = toDouble(c[0]);
        final lat = toDouble(c[1]);
        if (lat != null && lon != null) return (lat, lon);
      }
      final lon = toDouble(coords['lon'] ?? coords['lng'] ?? coords['longitude']);
      final lat = toDouble(coords['lat'] ?? coords['latitude']);
      if (lat != null && lon != null) return (lat, lon);
      return null;
    }

    final ll = extractLatLng();
    if (ll == null) {
      return _MapPlaceholder(onOpenFullMap: onOpenFullMap);
    }

    final user = LatLng(pos.latitude, pos.longitude);
    final branch = LatLng(ll.$1, ll.$2);
    final inside = match.isInside;
    final color = inside ? AppColors.successGreen : AppColors.warningOrange;

    final markers = <Marker>{
      Marker(markerId: const MarkerId('branch'), position: branch),
      Marker(
        markerId: const MarkerId('user'),
        position: user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('geofence'),
        center: branch,
        radius: match.radiusMeters.toDouble(),
        strokeColor: color,
        strokeWidth: 2,
        fillColor: color.withValues(alpha: 0.12),
      ),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenFullMap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: IgnorePointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: branch, zoom: 16),
                    markers: markers,
                    circles: circles,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    liteModeEnabled: true,
                    gestureRecognizers: {
                      Factory(() => EagerGestureRecognizer()),
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    inside ? Icons.verified : Icons.warning_amber_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${match.branch.nombre} • ${match.distanceMeters.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  const Icon(Icons.open_in_full, color: AppColors.neutral500),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.onOpenFullMap});

  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenFullMap,
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(14),
          child: const Row(
            children: [
              Icon(Icons.map_outlined, color: AppColors.neutral600),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ver mapa de la sucursal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
              ),
              Icon(Icons.open_in_full, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakQuickActions extends StatelessWidget {
  const _BreakQuickActions({
    required this.breakMin,
    required this.lastAttendance,
    required this.canStart,
    required this.canEnd,
    this.onStart,
    this.onEnd,
  });

  final int breakMin;
  final RegistrosAsistencia? lastAttendance;
  final bool canStart;
  final bool canEnd;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final last = lastAttendance;
    final now = DateTime.now();
    final elapsed = (last != null &&
            last.tipoRegistro == 'inicio_break' &&
            AttendanceHelper.isSameDay(last.fechaHoraMarcacion, now))
        ? now.difference(last.fechaHoraMarcacion)
        : null;
    final elapsedText = elapsed == null
        ? null
        : '${elapsed.inMinutes} min ${elapsed.inSeconds.remainder(60)} s';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.free_breakfast_outlined, color: AppColors.warningOrange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Descanso',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
                Text(
                  'Min: ${breakMin}m',
                  style: const TextStyle(color: AppColors.neutral600, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (elapsedText != null) ...[
              const SizedBox(height: 8),
              Text(
                'En descanso: $elapsedText',
                style: const TextStyle(color: AppColors.neutral700, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canStart ? onStart : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canEnd ? onEnd : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Terminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
