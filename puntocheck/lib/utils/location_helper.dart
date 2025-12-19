import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// Obtains current position with retries and fallback to last known.
  static Future<Position?> getCurrentLocation() async {
    Future<Position?> tryGet({
      LocationAccuracy accuracy = LocationAccuracy.best,
      Duration? timeLimit,
    }) {
      return Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
    }

    // 1. Ensure location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(
        'Los servicios de ubicacion estan desactivados. Por favor activalos.',
      );
    }

    // 2. Ensure permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permisos de ubicacion denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Permisos de ubicacion denegados permanentemente. Habilitalos en configuracion.',
      );
    }

    // 3. Try to get position with retries
    try {
      final primary = await tryGet(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );
      if (primary != null) return primary;
    } on TimeoutException {
      // continue to fallback
    } catch (_) {}

    try {
      final secondary = await tryGet(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 25),
      );
      if (secondary != null) return secondary;
    } on TimeoutException {
      // continue to fallback
    } catch (_) {}

    // Last resort: last known position
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;

    return Future.error('No se pudo obtener ubicacion (sin senal GPS). Intenta de nuevo.');
  }

  /// Open app settings so the user can enable permissions.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
