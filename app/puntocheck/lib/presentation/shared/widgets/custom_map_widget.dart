import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomMapWidget extends StatefulWidget {
  final LatLng? initialPosition;
  final double initialZoom;
  final bool showMyLocation;

  const CustomMapWidget({
    Key? key,
    this.initialPosition,
    this.initialZoom = 15,
    this.showMyLocation = true,
  }) : super(key: key);

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-3.9939, -79.2045); // Loja default
  bool _isLoading = true;
  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _initializeLocation();
  }

  /// Solicita ubicación solo UNA VEZ al inicio
  Future<void> _initializeLocation() async {
    if (widget.initialPosition != null) {
      _currentPosition = widget.initialPosition!;
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    if (widget.showMyLocation) {
      await _fetchLocation();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Obtiene ubicación y actualiza marker/cámara
  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position pos = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, _currentZoom),
      );
    } catch (e) {
      debugPrint("Error al obtener ubicación: $e");
    }
  }

  /// Recentrar: vuelve a pedir ubicación y mueve cámara
  void _recenter() async {
    await _fetchLocation();
  }

  void _zoomIn() {
    _currentZoom += 1;
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _zoomOut() {
    _currentZoom -= 1;
    _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: _currentZoom,
          ),
          markers: {
            Marker(markerId: const MarkerId("me"), position: _currentPosition),
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) => _mapController = controller,
        ),

        /// BOTONES
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "recenter",
                mini: true,
                child: const Icon(Icons.my_location),
                onPressed: _recenter,
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "zoom_in",
                mini: true,
                child: const Icon(Icons.add),
                onPressed: _zoomIn,
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "zoom_out",
                mini: true,
                child: const Icon(Icons.remove),
                onPressed: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
