import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminBranchMapView extends StatelessWidget {
  final Sucursales branch;

  const OrgAdminBranchMapView({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final center = branch.centerLatLng ?? const LatLng(-4.0033, -79.2030);

    return Scaffold(
      appBar: AppBar(
        title: Text(branch.nombre),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 16,
        ),
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        markers: {
          Marker(
            markerId: const MarkerId('branch'),
            position: center,
            infoWindow: InfoWindow(title: branch.nombre),
          ),
        },
        circles: {
          Circle(
            circleId: const CircleId('radius'),
            center: center,
            radius: (branch.radioMetros ?? 100).toDouble(),
            strokeColor: AppColors.primaryRed.withValues(alpha: 0.5),
            fillColor: AppColors.primaryRed.withValues(alpha: 0.18),
            strokeWidth: 2,
          ),
        },
      ),
    );
  }
}
