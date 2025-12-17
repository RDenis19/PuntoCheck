import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/providers/employee_providers.dart';
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
  LatLng? _nearestBranchCenter;
  bool _singleBranchContext = false;
  bool _overlayExpanded = false;

  // Tipo de registro seleccionado
  String _selectedType = 'entrada';

  // Evidence
  File? _evidencePhoto;
  final ImagePicker _picker = ImagePicker();

  // QR State
  MobileScannerController? _scannerController;
  bool _qrFound = false;
  String? _qrData;

  // General State
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  void _goToMyLocation() {
    if (_currentPosition == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        17,
      ),
    );
  }

  void _goToBranchLocation() {
    if (_nearestBranchCenter == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_nearestBranchCenter!, 17),
    );
  }

  Future<void> _fitToUserAndBranch() async {
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
    } catch (_) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(u, 16));
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.actionType;
    _tabController = TabController(length: 2, vsync: this);
    _initLocation();
    _startClock();

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // QR Tab
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
      setState(() {});
    });
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
        return AppColors.primaryRed;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _scannerController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _initLocation() async {
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
        _setupMapAndGeofences();
      }
    } catch (e) {
      if (mounted) _showError('Error de ubicación: $e');
      setState(() => _isLocating = false);
    }
  }

  Future<void> _setupMapAndGeofences() async {
    final List<Sucursales> branches = await ref.read(
      employeeBranchesProvider.future,
    );
    if (_currentPosition == null && branches.isEmpty) return;

    final myLat = _currentPosition?.latitude;
    final myLng = _currentPosition?.longitude;

    double minDistance = double.infinity;
    Sucursales? nearestBranch;
    LatLng? nearestCenter;

    final Set<Circle> newCircles = {};
    final Set<Marker> newMarkers = {};

    for (final branch in branches) {
      final center = branch.centerLatLng;
      if (center == null) continue;

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
        ),
      );
    }

    String statusMsg = 'Fuera de zona';
    Color statusCol = AppColors.warningOrange;
    bool inside = false;
    String? nBranchId;
    String? nBranchName;

    if (nearestBranch != null) {
      final double radius = (nearestBranch.radioMetros ?? 50).toDouble();
      nBranchName = nearestBranch.nombre;
      nBranchId = nearestBranch.id;

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

    if (mounted) {
      setState(() {
        _circles = newCircles;
        _markers = newMarkers;
        _locationStatus = statusMsg;
        _statusColor = statusCol;
        _isInsideGeofence = inside;
        _nearestBranchId = nBranchId;
        _nearestBranchName = nBranchName;
        _nearestBranchCenter = nearestCenter;
        _singleBranchContext = branches.length == 1;
        _fallbackCenter ??= nearestCenter;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToUserAndBranch();
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      preferredCameraDevice: CameraDevice.front,
    );
    if (photo != null) {
      setState(() => _evidencePhoto = File(photo.path));
    }
  }

  Future<void> _submitAttendance({bool isQr = false}) async {
    if (!isQr && _evidencePhoto == null) {
      _showError('La foto de evidencia es obligatoria en modo GPS.');
      return;
    }

    final controller = ref.read(employeeAttendanceControllerProvider.notifier);

    try {
      String? sucursalIdQr;
      if (isQr) {
        if (_qrData == null)
          throw Exception('No se ha escaneado ningún código QR');
        final qrInfo = await controller.validateQr(_qrData!);
        sucursalIdQr = qrInfo['sucursal_id'];
      }

      // 3. Registrar via provider/service
      await controller.registerAttendance(
        tipoRegistro: _selectedType,
        latitud: _currentPosition?.latitude ?? 0,
        longitud: _currentPosition?.longitude ?? 0,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrado exitosamente'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_qrFound) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() {
        _qrFound = true;
        _qrData = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Detectado: $code'),
          backgroundColor: AppColors.infoBlue,
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(employeeAttendanceControllerProvider)
        .isLoading;

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
        children: [_buildGpsTab(isSubmitting), _buildQrTab(isSubmitting)],
      ),
    );
  }

  Widget _buildGpsTab(bool isSubmitting) {
    return Stack(
      children: [
        if (_currentPosition != null || _fallbackCenter != null)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _fallbackCenter!,
              zoom: 17,
              tilt: 45,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            circles: _circles,
            markers: _markers,
            mapType: MapType.normal,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitToUserAndBranch();
              });
            },
          )
        else
          Container(
            color: AppColors.neutral100,
            child: const Center(child: CircularProgressIndicator()),
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
              firstChild: _buildOverlayCollapsed(),
              secondChild: _buildOverlayExpanded(),
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
                if (_evidencePhoto == null)
                  InkWell(
                    onTap: _takePhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.neutral100,
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.neutral600,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tomar Foto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _evidencePhoto!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.close, size: 18),
                        ),
                        onPressed: () => setState(() => _evidencePhoto = null),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        isSubmitting ||
                            _currentPosition == null ||
                            _evidencePhoto == null
                        ? null
                        : () => _submitAttendance(isQr: false),
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

  Widget _buildOverlayCollapsed() {
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
            onPressed: () => setState(() => _overlayExpanded = true),
            icon: const Icon(Icons.expand_more, color: AppColors.neutral700),
            tooltip: 'Ver detalles',
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayExpanded() {
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
                      items: const [
                        DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                        DropdownMenuItem(value: 'salida', child: Text('Salida')),
                        DropdownMenuItem(value: 'inicio_break', child: Text('Inicio break')),
                        DropdownMenuItem(value: 'fin_break', child: Text('Fin break')),
                      ],
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

  Widget _buildQrTab(bool isSubmitting) {
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _submitAttendance(isQr: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Registrar Asistencia',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _qrFound = false;
                  _qrData = null;
                }),
                child: const Text('Escanear otro'),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        if (_scannerController != null)
          MobileScanner(controller: _scannerController!, onDetect: _onQrDetect),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _corner(),
                    Transform.rotate(angle: 1.57, child: _corner()),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.rotate(angle: -1.57, child: _corner()),
                    Transform.rotate(angle: 3.14, child: _corner()),
                  ],
                ),
              ],
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
      ],
    );
  }

  Widget _corner() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primaryRed, width: 4),
          left: BorderSide(color: AppColors.primaryRed, width: 4),
        ),
      ),
    );
  }
}
