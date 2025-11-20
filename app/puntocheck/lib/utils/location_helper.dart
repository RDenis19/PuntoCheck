import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// Obtiene la posición actual del dispositivo con alta precisión
  static Future<Position?> getCurrentLocation() async {
    // 1. Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están desactivados. Por favor actívalos.');
    }

    // 2. Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permisos de ubicación denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Permisos de ubicación denegados permanentemente. Habilítalos en configuración.');
    }

    // 3. Obtener posición actual con la mejor precisión posible
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // Usar la mejor precisión disponible
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return Future.error('Error al obtener ubicación: $e');
    }
  }

  /// Abre la configuración de la aplicación para habilitar permisos
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
