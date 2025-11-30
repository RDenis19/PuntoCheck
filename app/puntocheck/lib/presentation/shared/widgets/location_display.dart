import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:puntocheck/utils/location_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class LocationDisplay extends StatefulWidget {
  const LocationDisplay({
    super.key,
    required this.onLocationChanged,
  });

  final ValueChanged<Position?> onLocationChanged;

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
        _currentPosition = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      widget.onLocationChanged(null);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentPosition != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(
                hasLocation ? Icons.location_on : Icons.location_disabled,
                color: hasLocation ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasLocation ? 'Ubicacion capturada' : 'Ubicacion pendiente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (hasLocation)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasLocation && !_isLoading) ...[
            _StatusText(
              text: _error ?? 'Aun no se obtiene la ubicacion.',
              color: _error != null ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Obtener ubicacion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (hasLocation) ...[
            _InfoRow(
              icon: Icons.my_location,
              label: 'Latitud',
              value: _currentPosition!.latitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.map_outlined,
              label: 'Longitud',
              value: _currentPosition!.longitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.speed,
              label: 'Precision',
              value: '${_currentPosition!.accuracy.toStringAsFixed(1)} m',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar ubicacion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.backgroundDark.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.backgroundDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
