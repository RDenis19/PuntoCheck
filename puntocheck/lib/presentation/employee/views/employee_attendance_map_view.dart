import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeAttendanceMapView extends StatefulWidget {
  const EmployeeAttendanceMapView({
    super.key,
    required this.user,
    required this.branch,
    required this.radiusMeters,
    required this.branchName,
    this.branchAddress,
    required this.insideGeofence,
  });

  final LatLng user;
  final LatLng branch;
  final int radiusMeters;
  final String branchName;
  final String? branchAddress;
  final bool insideGeofence;

  @override
  State<EmployeeAttendanceMapView> createState() => _EmployeeAttendanceMapViewState();
}

class _EmployeeAttendanceMapViewState extends State<EmployeeAttendanceMapView> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inside = widget.insideGeofence;
    final statusColor = inside ? AppColors.successGreen : AppColors.warningOrange;
    final statusText = inside ? 'Dentro de geocerca' : 'Fuera de geocerca';

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('branch'),
        position: widget.branch,
        infoWindow: InfoWindow(title: widget.branchName),
      ),
      Marker(
        markerId: const MarkerId('user'),
        position: widget.user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('geofence'),
        center: widget.branch,
        radius: widget.radiusMeters.toDouble(),
        strokeColor: statusColor,
        strokeWidth: 2,
        fillColor: statusColor.withValues(alpha: 0.12),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de sucursal'),
        backgroundColor: AppColors.primaryRed,
        surfaceTintColor: AppColors.primaryRed,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: widget.branch, zoom: 16),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: markers,
              circles: circles,
              onMapCreated: (c) async {
                _controller = c;
                await _fitBounds();
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.neutral200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.branchName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                    fontSize: 16,
                  ),
                ),
                if ((widget.branchAddress ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.branchAddress!.trim(),
                    style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      inside ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _fitBounds,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                      label: const Text('Ajustar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;

    final u = widget.user;
    final b = widget.branch;

    final sw = LatLng(
      u.latitude < b.latitude ? u.latitude : b.latitude,
      u.longitude < b.longitude ? u.longitude : b.longitude,
    );
    final ne = LatLng(
      u.latitude > b.latitude ? u.latitude : b.latitude,
      u.longitude > b.longitude ? u.longitude : b.longitude,
    );

    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 90),
      );
    } catch (_) {
      // Si falla el bounds (algunos dispositivos al iniciar), hacemos fallback a zoom fijo.
      await c.animateCamera(CameraUpdate.newLatLngZoom(widget.branch, 16));
    }
  }
}
