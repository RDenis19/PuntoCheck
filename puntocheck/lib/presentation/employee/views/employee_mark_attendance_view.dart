import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/presentation/employee/views/employee_qr_scan_view.dart';
import 'package:puntocheck/services/attendance_helper.dart';
import 'package:puntocheck/services/employee_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeMarkAttendanceView extends ConsumerStatefulWidget {
  final String actionType; // 'entrada' o 'salida'

  const EmployeeMarkAttendanceView({super.key, required this.actionType});

  @override
  ConsumerState<EmployeeMarkAttendanceView> createState() =>
      _EmployeeMarkAttendanceViewState();
}

class _EmployeeMarkAttendanceViewState
    extends ConsumerState<EmployeeMarkAttendanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _autoTypeKey;
  bool _suspendPlatformViews = false;
  int _mapEpoch = 0;
  bool _disposed = false;

  // GPS State
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _fallbackCenter;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  bool _isLocating = true;
  String _locationStatus = 'Localizando...';
  Color _statusColor = AppColors.neutral500;
	  bool _isInsideGeofence = false;
	  String? _nearestBranchId;
	  String? _nearestBranchName;
	  String? _nearestBranchAddress;
	  LatLng? _nearestBranchCenter;
	  bool _singleBranchContext = false;
	  bool _overlayExpanded = false;

  // Tipo de registro seleccionado
  String _selectedType = 'entrada';

  // Evidence
  File? _evidencePhoto;
  final ImagePicker _picker = ImagePicker();

  // QR State
  bool _qrFound = false;
  String? _qrData;

  // General State
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  String? _inlineMessage;
  bool _inlineIsError = false;
  void _goToMyLocation() {
    if (_currentPosition == null || _mapController == null || _disposed) return;
    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          17,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error animating to location: $e');
    }
  }

  void _goToBranchLocation() {
    if (_nearestBranchCenter == null || _mapController == null || _disposed) return;
    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_nearestBranchCenter!, 17),
      );
    } catch (e) {
      if (kDebugMode) print('Error animating to branch: $e');
    }
  }

  Future<void> _fitToUserAndBranch() async {
    if (_disposed) return;

    final controller = _mapController;
    final user = _currentPosition;
    final branch = _nearestBranchCenter;
    if (controller == null || user == null || branch == null) return;

    final u = LatLng(user.latitude, user.longitude);
    final b = branch;

    final sw = LatLng(
      u.latitude < b.latitude ? u.latitude : b.latitude,
      u.longitude < b.longitude ? u.longitude : b.longitude,
    );
    final ne = LatLng(
      u.latitude > b.latitude ? u.latitude : b.latitude,
      u.longitude > b.longitude ? u.longitude : b.longitude,
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          70,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error fitting bounds: $e');
      if (!_disposed) {
        try {
          await controller.animateCamera(CameraUpdate.newLatLngZoom(u, 16));
        } catch (_) {
          // Ignore final fallback error
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.actionType;
    _tabController = TabController(length: 2, vsync: this);
    _initLocation();
    _startClock();
    _recoverLostEvidenceIfAny();
  }

  Future<File?> _persistXFileToTemp(XFile source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) return null;

    final filename = 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outFile = File('${Directory.systemTemp.path}/$filename');
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }

  Future<void> _recoverLostEvidenceIfAny() async {
    if (!Platform.isAndroid) return;
    if (_evidencePhoto != null) return;

    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;

      final XFile? lost = response.file ??
          ((response.files?.isNotEmpty ?? false) ? response.files!.first : null);
      if (lost == null) return;

      final file = await _persistXFileToTemp(lost);
      if (!mounted) return;
      if (file == null) return;

      setState(() => _evidencePhoto = file);
      _showInfo('Foto recuperada. Ya puedes confirmar.');
    } catch (_) {
      // ignore: recuperación best-effort
    }
  }

  List<String> _allowedTypesFor(RegistrosAsistencia? last, DateTime now) {
    return AttendanceHelper.getAllowedTypes(last, now);
  }

  String _nextTypeAfter(String current) {
    return AttendanceHelper.getNextType(current);
  }

  String _labelForType(String type) {
    return AttendanceHelper.getTypeLabel(type);
  }

  Color _colorForType(String type) {
    final hexColor = AttendanceHelper.getTypeColor(type);
    // Convertir hex a color
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return AttendanceHelper.isSameDay(a, b);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _tabController.dispose();
    _disposeMapController();
    super.dispose();
  }

  void _disposeMapController() {
    try {
      _mapController?.dispose();
      _mapController = null;
    } catch (e) {
      // Ignore disposal errors - Google Maps sometimes throws during cleanup
      if (kDebugMode) {
        print('Error disposing GoogleMapController: $e');
      }
    }
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _initLocation() async {
    if (mounted) setState(() => _isLocating = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showError('Servicios de ubicación desactivados');
      setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showError('Permiso de ubicación denegado');
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showError('Permiso denegado permanentemente');
      setState(() => _isLocating = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocating = false;
        });
        _setupMapAndGeofences(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) _showError('Error de ubicación: $e');
      setState(() => _isLocating = false);
    }
  }

  Future<void> _setupMapAndGeofences({bool forceRefresh = false}) async {
    if (_disposed) return;

    List<Sucursales> branches;
    try {
      branches = forceRefresh
          ? await ref.refresh(employeeBranchesProvider.future)
          : await ref.read(employeeBranchesProvider.future);
    } catch (e) {
      if (!mounted || _disposed) return;
      // Clear old data before setting error state
      _clearMapData();
      setState(() {
        _nearestBranchId = null;
        _nearestBranchName = null;
        _nearestBranchAddress = null;
        _nearestBranchCenter = null;
        _isInsideGeofence = false;
        _statusColor = AppColors.warningOrange;
        _locationStatus = 'No se pudo cargar tu sucursal (revisa permisos/RLS)';
      });
      return;
    }
    if (_currentPosition == null && branches.isEmpty) return;

    final myLat = _currentPosition?.latitude;
    final myLng = _currentPosition?.longitude;

    double minDistance = double.infinity;
    Sucursales? nearestBranch;
    LatLng? nearestCenter;

    final Set<Circle> newCircles = {};
    final Set<Marker> newMarkers = {};
    var branchesWithGeo = 0;

    for (final branch in branches) {
      final center = branch.centerLatLng;
      if (center == null) continue;
      branchesWithGeo += 1;

      final double radius = (branch.radioMetros ?? 50).toDouble();
      final dist = (myLat != null && myLng != null)
          ? Geolocator.distanceBetween(
              myLat,
              myLng,
              center.latitude,
              center.longitude,
            )
          : double.infinity;

      if (dist < minDistance) {
        minDistance = dist;
        nearestBranch = branch;
        nearestCenter = center;
      }

      newCircles.add(
        Circle(
          circleId: CircleId(branch.id),
          center: center,
          radius: radius,
          fillColor: AppColors.primaryRed.withValues(alpha: 0.1),
          strokeColor: AppColors.primaryRed,
          strokeWidth: 1,
        ),
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(branch.id),
          position: center,
          infoWindow: InfoWindow(title: branch.nombre),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    String statusMsg = 'Fuera de zona';
    Color statusCol = AppColors.warningOrange;
    bool inside = false;
    String? nBranchId;
    String? nBranchName;
    String? nBranchAddress;
    final userLatLng =
        (myLat != null && myLng != null) ? LatLng(myLat, myLng) : null;

    if (branches.isNotEmpty && branchesWithGeo == 0) {
      // Aun si no hay geocerca configurada, el empleado igual pertenece a una sucursal.
      nBranchName = branches.first.nombre;
      nBranchId = branches.first.id;
      nBranchAddress = branches.first.direccion;
      statusMsg = 'Tu sucursal no tiene ubicación (ubicacion_central)';
      statusCol = AppColors.warningOrange;
      inside = false;
    } else if (branches.isEmpty) {
      statusMsg = 'No se pudo cargar tu sucursal (revisa permisos/RLS)';
      statusCol = AppColors.warningOrange;
      inside = false;
    } else if (nearestBranch != null) {
      final double radius = (nearestBranch.radioMetros ?? 50).toDouble();
      nBranchName = nearestBranch.nombre;
      nBranchId = nearestBranch.id;
      nBranchAddress = nearestBranch.direccion;

      if (minDistance <= radius) {
        statusMsg = 'Dentro de: ${nearestBranch.nombre}';
        statusCol = AppColors.successGreen;
        inside = true;
      } else {
        statusMsg =
            'Fuera de: ${nearestBranch.nombre} (${minDistance.toStringAsFixed(0)}m)';
      }
    } else {
      statusMsg = 'Sin sucursales cercanas';
    }

    if (mounted && !_disposed) {
      // Clear old map data before assigning new data
      _clearMapData();

      setState(() {
        _circles = newCircles;
        _markers = newMarkers;
        _locationStatus = statusMsg;
        _statusColor = statusCol;
        _isInsideGeofence = inside;
        _nearestBranchId = nBranchId;
        _nearestBranchName = nBranchName;
        _nearestBranchAddress = nBranchAddress;
        _nearestBranchCenter = nearestCenter;
        _singleBranchContext = branches.length == 1;
        _fallbackCenter ??= nearestCenter ?? userLatLng;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          _fitToUserAndBranch();
        }
      });
    }
  }

  void _clearMapData() {
    _circles.clear();
    _markers.clear();
  }

  Future<void> _refreshBranchInfo() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    await _setupMapAndGeofences(forceRefresh: true);
    if (!mounted) return;
    setState(() => _isLocating = false);
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        if (status.isPermanentlyDenied) {
          _showError(
            'Permiso de cámara denegado permanentemente. Actívalo en Ajustes para poder marcar asistencia.',
          );
          await openAppSettings();
          return;
        }
        _showError('Permiso de cámara denegado.');
        return;
      }

      // Workaround (MIUI/Adreno + PlatformViews): al abrir la cámara desde una pantalla con
      // GoogleMap/MobileScanner, algunos dispositivos devuelven "cancelado" por fallas de GPU/surfaces.
      if (mounted) setState(() => _suspendPlatformViews = true);
      _disposeMapController();
      await Future<void>.delayed(const Duration(milliseconds: 180));

      Future<XFile?> pickWith(CameraDevice device) {
        return _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 40,
          maxWidth: 1280,
          maxHeight: 1280,
          preferredCameraDevice: device,
        );
      }

      // 1) Intentar cámara frontal (selfie)
      XFile? photo = await pickWith(CameraDevice.front);
      if (!mounted) return;

      if (photo == null) {
        // 2) Intentar recuperar "lost data" (Android)
        await _recoverLostEvidenceIfAny();
        if (!mounted) return;
      }

      if (photo == null && _evidencePhoto == null) {
        // 3) Fallback: intentar cámara trasera (mejor capturar algo que bloquear al usuario)
        photo = await pickWith(CameraDevice.rear);
        if (!mounted) return;
      }

      if (_evidencePhoto == null && photo == null) {
        _showError(
          'Captura cancelada. Si usas Xiaomi/MIUI, desactiva el ahorro de batería para PuntoCheck y reintenta.',
        );
        return;
      }

      if (_evidencePhoto == null && photo != null) {
        final outFile = await _persistXFileToTemp(photo);
        if (outFile == null) {
          setState(() => _evidencePhoto = null);
          _showError('No se pudo leer la foto capturada. Reintenta.');
          return;
        }

        setState(() => _evidencePhoto = outFile);
        _showInfo('Foto guardada (se sube al confirmar)');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(
        'No se pudo abrir la cámara. Revisa permisos de cámara y vuelve a intentar. ($e)',
      );
    } finally {
      if (mounted) {
        setState(() {
          _suspendPlatformViews = false;
          _mapEpoch += 1;
        });
      }
    }
  }

  Future<void> _scanQr() async {
    _setInlineMessage('', isError: false);

    if (mounted) setState(() => _suspendPlatformViews = true);
    _disposeMapController();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    String? code;
    try {
      code = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const EmployeeQrScanView()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _suspendPlatformViews = false;
          _mapEpoch += 1;
        });
      }
    }
    if (!mounted) return;

    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty) {
      _showError('Escaneo cancelado.');
      return;
    }
    setState(() {
      _qrFound = true;
      _qrData = trimmed;
    });
    _showInfo('QR detectado');
  }

  void _removePhoto() => setState(() => _evidencePhoto = null);

  Widget _buildEvidencePicker() {
    final hasPhoto = _evidencePhoto != null;

    final borderColor = hasPhoto ? AppColors.successGreen : AppColors.primaryRed;
    final bgColor = hasPhoto
        ? AppColors.successGreen.withValues(alpha: 0.08)
        : AppColors.neutral100;

    if (!hasPhoto) {
      return InkWell(
        onTap: _takePhoto,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            border: Border.all(color: borderColor),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: AppColors.primaryRed),
              SizedBox(width: 10),
              Text(
                'Tomar foto (obligatoria)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Foto guardada (se sube al confirmar)',
	                style: TextStyle(
	                  fontWeight: FontWeight.w700,
	                  color: AppColors.neutral700,
	                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              _evidencePhoto!,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Volver a tomar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neutral700,
                  side: const BorderSide(color: AppColors.neutral300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _removePhoto,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Quitar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.neutral300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitAttendance({bool isQr = false}) async {
    _setInlineMessage('', isError: false);
    if (!isQr && _currentPosition == null) {
      _showError('No se pudo obtener tu ubicación. Activa GPS y reintenta.');
      return;
    }

    if (_evidencePhoto == null) {
      _showError('Debes tomar una foto para registrar la asistencia.');
      return;
    }

    final lastAttendance = ref.read(lastAttendanceProvider).valueOrNull;
    final typeRestriction = _typeRestrictionMessage(
      lastAttendance,
      DateTime.now(),
      _selectedType,
    );
    if (typeRestriction != null) {
      _showError(typeRestriction);
      return;
    }

    if (!isQr && _selectedType == 'entrada') {
      final schedule = ref.read(employeeScheduleProvider).valueOrNull;
      final legalCfg =
          ref.read(employeeLegalConfigProvider).valueOrNull ?? const <String, dynamic>{};
      final toleranceMin = schedule?.plantilla.toleranciaEntradaMinutos ??
          _asInt(legalCfg['tolerancia_entrada_min']) ??
          15;
      final latestEntry = _computeLatestEntryTime(schedule, toleranceMin);
      if (latestEntry != null && DateTime.now().isAfter(latestEntry)) {
        _showError(
          'Tolerancia vencida. Límite: ${DateFormat('HH:mm').format(latestEntry)}',
        );
        return;
      }
    }

    final controller = ref.read(employeeAttendanceControllerProvider.notifier);

    try {
      _setInlineMessage('Registrando asistencia...', isError: false);
      String? sucursalIdQr;
      if (isQr) {
        if (_qrData == null) {
          throw Exception('No se ha escaneado ningún código QR');
        }
        final qrInfo = await controller.validateQr(_qrData!);
        sucursalIdQr = qrInfo['sucursal_id'];
      }

      // Registrar via provider/service
      final lat = _currentPosition?.latitude;
      final lng = _currentPosition?.longitude;
      final result = await controller.registerAttendance(
        tipoRegistro: _selectedType,
        latitud: lat,
        longitud: lng,
        sucursalId: isQr ? sucursalIdQr : _nearestBranchId,
        estaDentroGeocerca: isQr ? true : _isInsideGeofence,
        notas: isQr ? 'Validado por QR' : 'Registro GPS',
        isQr: isQr,
        evidenciaPhoto: _evidencePhoto,
        precisionMetros: _currentPosition?.accuracy,
      );

      final state = ref.read(employeeAttendanceControllerProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Error desconocido');
      }

      if (mounted) {
        _showSuccess(_buildSuccessMessage(result));
        setState(() {
          _evidencePhoto = null;
          _selectedType = _nextTypeAfter(_selectedType);
        });
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  String _buildSuccessMessage(Map<String, dynamic>? result) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    final dentro = result?['dentro_rango'] == true ||
        result?['dentro'] == true ||
        result?['esta_dentro'] == true;
    final distancia = (result?['distancia'] ?? result?['distance']) as num?;

    final zoneStr = dentro ? 'EN ZONA' : 'FUERA DE ZONA';
    final extra = distancia != null ? ' • ${distancia.toStringAsFixed(0)}m' : '';
    return 'Marcación registrada ($zoneStr) • $timeStr$extra';
  }

  void _setInlineMessage(String msg, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = msg;
      _inlineIsError = isError;
    });
  }

  void _showInfo(String msg) {
    _setInlineMessage(msg, isError: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.infoBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String msg) {
    _setInlineMessage(msg, isError: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.successGreen),
    );
  }

  void _showError(String msg) {
    _setInlineMessage(msg, isError: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(employeeAttendanceControllerProvider)
        .isLoading;

    final lastAttendanceAsync = ref.watch(lastAttendanceProvider);
    final lastAttendance = lastAttendanceAsync.valueOrNull;
    final sequenceAllowedTypes = _allowedTypesFor(lastAttendance, DateTime.now());
    final orderedAllTypes = const ['entrada', 'inicio_break', 'fin_break', 'salida'];
    final allowedSet = <String>{...sequenceAllowedTypes, _selectedType};
    final allowedTypes = orderedAllTypes.where(allowedSet.contains).toList();

    // Auto-ajusta el tipo si el estado actual no permite la selección (ej: está en descanso).
    final nextKey =
        '${lastAttendance?.id ?? 'none'}|${sequenceAllowedTypes.join(',')}';
    final canAutoAdjust = !lastAttendanceAsync.isLoading &&
        lastAttendance != null &&
        _isSameDay(lastAttendance.fechaHoraMarcacion, DateTime.now());
    if (canAutoAdjust &&
        sequenceAllowedTypes.isNotEmpty &&
        !sequenceAllowedTypes.contains(_selectedType) &&
        _autoTypeKey != nextKey) {
      _autoTypeKey = nextKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedType = sequenceAllowedTypes.first);
      });
    }

    final typeRestriction = _typeRestrictionMessage(
      lastAttendance,
      DateTime.now(),
      _selectedType,
    );

    final schedule = ref.watch(employeeScheduleProvider).valueOrNull;
    final legalCfg = ref.watch(employeeLegalConfigProvider).valueOrNull ?? const <String, dynamic>{};

    final breakMin = _asInt(legalCfg['tiempo_descanso_min']) ?? 60;
    final toleranceMin = schedule?.plantilla.toleranciaEntradaMinutos ??
        _asInt(legalCfg['tolerancia_entrada_min']) ??
        15;
    final latestEntry = _computeLatestEntryTime(schedule, toleranceMin);
    final shiftLabel = _buildShiftLabel(schedule);
    final isToleranceExpired = _selectedType == 'entrada' &&
        latestEntry != null &&
        DateTime.now().isAfter(latestEntry);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registrar Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primaryRed,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Ubicación GPS'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildGpsTab(
            isSubmitting,
            isToleranceExpired,
            latestEntry,
            breakMin,
            toleranceMin,
            typeRestriction,
            shiftLabel,
            allowedTypes,
          ),
          _buildQrTab(
            isSubmitting,
            breakMin,
            toleranceMin,
            typeRestriction,
            _tabController.index == 1,
          ),
        ],
      ),
    );
  }

  String? _typeRestrictionMessage(
    RegistrosAsistencia? last,
    DateTime now,
    String selectedType,
  ) {
    final result = AttendanceHelper.validateRegistroType(selectedType, last, now);
    return result.isValid ? null : result.errorMessage;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  _ShiftRange? _computeShiftRange(EmployeeSchedule? schedule) {
    final range = AttendanceHelper.computeShiftRange(schedule?.plantilla);
    if (range == null) return null;
    return _ShiftRange(start: range.start, end: range.end, endsNextDay: range.endsNextDay);
  }

  DateTime? _computeLatestEntryTime(EmployeeSchedule? schedule, int toleranceMin) {
    return AttendanceHelper.computeLatestEntryTime(schedule?.plantilla, toleranceMin);
  }

  String? _buildShiftLabel(EmployeeSchedule? schedule) {
    final range = _computeShiftRange(schedule);
    if (range == null) return null;

    final startStr = DateFormat('HH:mm').format(range.start);
    final endStr = DateFormat('HH:mm').format(range.end);
    final suffix = range.endsNextDay ? ' (+1)' : '';
    return 'Jornada: $startStr - $endStr$suffix';
  }

  String? _buildLatestEntryLabel(DateTime? latestEntry) {
    if (latestEntry == null) return null;
    return 'Entrada hasta: ${DateFormat('HH:mm').format(latestEntry)}';
  }

  Widget _buildGpsTab(
    bool isSubmitting,
    bool isToleranceExpired,
    DateTime? latestEntry,
    int breakMin,
    int toleranceMin,
    String? typeRestriction,
    String? shiftLabel,
    List<String> allowedTypes,
  ) {
    final canSubmit = !isSubmitting &&
        _evidencePhoto != null &&
        _currentPosition != null &&
        _nearestBranchId != null &&
        !(isToleranceExpired && _selectedType == 'entrada') &&
        typeRestriction == null;

    return Stack(
      children: [
        if (_suspendPlatformViews)
          Container(
            color: AppColors.neutral100,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          )
        else if (_currentPosition != null || _fallbackCenter != null)
          GoogleMap(
            key: ValueKey('employee_google_map_$_mapEpoch'),
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _fallbackCenter!,
              zoom: 17,
            ),
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: _currentPosition != null,
            circles: _circles,
            markers: _markers,
            mapType: MapType.normal,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_disposed) {
                  _fitToUserAndBranch();
                }
              });
            },
          )
        else
          Container(
            color: AppColors.neutral100,
            child: Center(
              child: _isLocating
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No se pudo obtener tu ubicación',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Revisa permisos/GPS y reintenta.',
                          style: TextStyle(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _initLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
            ),
          ),

        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _overlayExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildOverlayCollapsed(breakMin, toleranceMin),
              secondChild: _buildOverlayExpanded(
                breakMin,
                toleranceMin,
                shiftLabel: shiftLabel,
                latestEntry: latestEntry,
                allowedTypes: allowedTypes,
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 190,
          child: FloatingActionButton.small(
            heroTag: 'recenter_gps',
            backgroundColor: Colors.white,
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location, color: AppColors.primaryRed),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 130,
          child: FloatingActionButton.small(
            heroTag: 'recenter_branch',
            backgroundColor: Colors.white,
            onPressed: _nearestBranchCenter == null ? null : _goToBranchLocation,
            child: const Icon(
              Icons.store_mall_directory,
              color: AppColors.primaryRed,
            ),
          ),
        ),

        // Actions Bottom Panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEvidencePicker(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canSubmit ? () => _submitAttendance(isQr: false) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorForType(_selectedType),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'CONFIRMAR ${_selectedType.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
	                  ),
	                ),
	                if (!isSubmitting &&
	                    (_inlineMessage != null && _inlineMessage!.trim().isNotEmpty))
	                  Padding(
	                    padding: const EdgeInsets.only(top: 10),
	                    child: Text(
	                      _inlineMessage!,
	                      style: TextStyle(
	                        fontSize: 12,
	                        color: _inlineIsError
	                            ? AppColors.errorRed
	                            : AppColors.neutral600,
	                        fontWeight: FontWeight.w600,
	                      ),
	                      textAlign: TextAlign.center,
	                    ),
	                  ),
	                if (!isSubmitting &&
	                    (_evidencePhoto == null ||
	                        _currentPosition == null ||
	                        _nearestBranchId == null ||
                        (isToleranceExpired && _selectedType == 'entrada') ||
                        typeRestriction != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _evidencePhoto == null
                          ? 'Toma la foto para habilitar el botón.'
                          : (_currentPosition == null
                              ? 'Esperando GPS...'
                              : (_nearestBranchId == null
                                  ? 'No se pudo identificar tu sucursal. Refresca el mapa.'
                                  : (typeRestriction ??
                                      (isToleranceExpired && _selectedType == 'entrada'
                                          ? 'Tolerancia vencida. Límite: ${DateFormat('HH:mm').format(latestEntry!)}'
                                          : '')))),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
	                      textAlign: TextAlign.center,
	                    ),
	                  ),
	                if (kDebugMode) ...[
	                  const SizedBox(height: 6),
	                  Text(
	                    'Debug: suspended=$_suspendPlatformViews gps=${_currentPosition != null} sucursal=${_nearestBranchId != null} foto=${_evidencePhoto != null} fotoPath=${_evidencePhoto?.path} zona=$_isInsideGeofence',
	                    style: const TextStyle(
	                      fontSize: 10,
	                      color: AppColors.neutral500,
	                    ),
	                  ),
	                ],
	              ],
	            ),
	          ),
	        ),
      ],
    );
  }

  Widget _buildOverlayCard({required Widget child}) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildOverlayCollapsed(int breakMin, int toleranceMin) {
    final branchLabel = _nearestBranchName == null
        ? 'Sucursal: --'
        : (_singleBranchContext
            ? 'Sucursal: $_nearestBranchName'
            : 'Cerca de: $_nearestBranchName');

    return _buildOverlayCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor),
                const SizedBox(width: 6),
                Text(
                  _isInsideGeofence ? 'EN ZONA' : 'FUERA',
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              branchLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
          ),
          IconButton(
            onPressed: _refreshBranchInfo,
            icon: const Icon(Icons.refresh, color: AppColors.neutral700),
            tooltip: 'Actualizar sucursal',
          ),
          IconButton(
            onPressed: () => setState(() => _overlayExpanded = true),
            icon: const Icon(Icons.expand_more, color: AppColors.neutral700),
            tooltip: 'Ver detalles',
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayExpanded(
    int breakMin,
    int toleranceMin, {
    String? shiftLabel,
    DateTime? latestEntry,
    required List<String> allowedTypes,
  }) {
    final branchLabel = _nearestBranchName == null
        ? 'Buscando sucursal...'
        : (_singleBranchContext
            ? 'Sucursal: $_nearestBranchName'
            : 'Cerca de: $_nearestBranchName');

    return _buildOverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(_currentTime),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM yyyy', 'es').format(_currentTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshBranchInfo,
                icon: const Icon(Icons.refresh, color: AppColors.neutral700),
                tooltip: 'Actualizar sucursal',
              ),
              IconButton(
                onPressed: () => setState(() => _overlayExpanded = false),
                icon: const Icon(Icons.expand_less, color: AppColors.neutral700),
                tooltip: 'Minimizar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isDense: true,
                      items: allowedTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_labelForType(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: _statusColor),
                    const SizedBox(width: 6),
                    Text(
                      _isInsideGeofence ? 'EN ZONA' : 'FUERA DE ZONA',
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place, size: 16, color: AppColors.neutral500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branchLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_nearestBranchAddress != null &&
              _nearestBranchAddress!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _nearestBranchAddress!,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (shiftLabel != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                shiftLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Descanso: $breakMin min • Tolerancia entrada: $toleranceMin min',
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (latestEntry != null) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _buildLatestEntryLabel(latestEntry)!,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _locationStatus,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrTab(
    bool isSubmitting,
    int breakMin,
    int toleranceMin,
    String? typeRestriction,
    bool isActive,
  ) {
    if (!isActive) return const SizedBox.shrink();
    final canSubmit =
        !isSubmitting && _evidencePhoto != null && typeRestriction == null;
    if (_qrFound) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.successGreen,
              ),
              const SizedBox(height: 20),
              const Text(
                'QR Validado',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _qrData ?? '',
                style: const TextStyle(color: AppColors.neutral600),
              ),
	              const SizedBox(height: 20),
	              _buildEvidencePicker(),
	              const SizedBox(height: 16),
	              SizedBox(
	                width: double.infinity,
	                child: ElevatedButton(
	                  onPressed:
	                      canSubmit ? () => _submitAttendance(isQr: true) : null,
	                  style: ElevatedButton.styleFrom(
	                    backgroundColor: _colorForType(_selectedType),
	                    padding: const EdgeInsets.symmetric(vertical: 16),
	                  ),
	                  child: Text(
	                    'Registrar ${_labelForType(_selectedType)}',
	                    style: const TextStyle(color: Colors.white, fontSize: 18),
	                  ),
	                ),
	              ),
	              if (!isSubmitting &&
	                  (_inlineMessage != null && _inlineMessage!.trim().isNotEmpty))
	                Padding(
	                  padding: const EdgeInsets.only(top: 10),
	                  child: Text(
	                    _inlineMessage!,
	                    style: TextStyle(
	                      fontSize: 12,
	                      color: _inlineIsError
	                          ? AppColors.errorRed
	                          : AppColors.neutral600,
	                      fontWeight: FontWeight.w600,
	                    ),
	                    textAlign: TextAlign.center,
	                  ),
	                ),
              if (!isSubmitting && _evidencePhoto == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Toma la foto para habilitar el botón.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!isSubmitting && typeRestriction != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    typeRestriction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _qrFound = false;
                    _qrData = null;
                  });
                },
                child: const Text('Escanear otro'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 90, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Escanea el QR de la sucursal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esto abrirá la cámara en una pantalla separada para evitar conflictos con el mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _scanQr,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Abrir escáner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftRange {
  final DateTime start;
  final DateTime end;
  final bool endsNextDay;

  const _ShiftRange({
    required this.start,
    required this.end,
    required this.endsNextDay,
  });
}
