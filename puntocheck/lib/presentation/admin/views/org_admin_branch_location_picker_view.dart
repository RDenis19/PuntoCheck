import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class BranchLocationResult {
  final LatLng position;
  final double radius;

  BranchLocationResult({required this.position, required this.radius});
}

class OrgAdminBranchLocationPickerView extends StatefulWidget {
  final LatLng initialPosition;
  final double initialRadius;

  const OrgAdminBranchLocationPickerView({
    super.key,
    required this.initialPosition,
    required this.initialRadius,
  });

  @override
  State<OrgAdminBranchLocationPickerView> createState() => _OrgAdminBranchLocationPickerViewState();
}

class _OrgAdminBranchLocationPickerViewState extends State<OrgAdminBranchLocationPickerView> {
  late LatLng _position;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _radius = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicacion de sucursal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _position, zoom: 16),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onTap: (latLng) {
              setState(() {
                _position = latLng;
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId('branch'),
                position: _position,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            circles: {
              Circle(
                circleId: const CircleId('radius'),
                center: _position,
                radius: _radius,
                strokeColor: AppColors.primaryRed.withValues(alpha: 0.45),
                fillColor: AppColors.primaryRed.withValues(alpha: 0.16),
                strokeWidth: 2,
              ),
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: _CoordBadge(
                    label: 'Latitud',
                    value: _position.latitude.toStringAsFixed(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CoordBadge(
                    label: 'Longitud',
                    value: _position.longitude.toStringAsFixed(6),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            activeColor: AppColors.primaryRed,
                            onChanged: (v) => setState(() => _radius = v),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(
                                BranchLocationResult(position: _position, radius: _radius),
                              );
                            },
                            label: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
          Text(label, style: const TextStyle(color: AppColors.neutral600, fontSize: 12)),
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
