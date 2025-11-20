import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:puntocheck/utils/location_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class LocationDisplay extends StatefulWidget {
  final Function(Position?) onLocationChanged;

  const LocationDisplay({
    super.key,
    required this.onLocationChanged,
  });

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationHelper.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      widget.onLocationChanged(position);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ubicación GPS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentPosition != null)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (_currentPosition == null && !_isLoading)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.location_off_outlined,
                      size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Ubicación no registrada',
                    style: TextStyle(
                      color: _error != null ? Colors.red : Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Obtener Ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                _buildInfoRow(Icons.map, 'Latitud',
                    _currentPosition!.latitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.map, 'Longitud',
                    _currentPosition!.longitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.speed, 'Precisión',
                    '±${_currentPosition!.accuracy.toStringAsFixed(1)} m'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar Ubicación'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
