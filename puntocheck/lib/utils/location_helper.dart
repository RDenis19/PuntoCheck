import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// Obtiene la posición actual con reintentos y fallback a la última conocida.
  static Future<Position?> getCurrentLocation() async {
    
    // Función auxiliar actualizada para la nueva versión de Geolocator (v10+)
    Future<Position?> tryGet({
      LocationAccuracy accuracy = LocationAccuracy.best,
      Duration? timeLimit,
    }) async {
      return await Geolocator.getCurrentPosition(
        // AQUI ESTABA EL ERROR: Ahora se usa locationSettings
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    }

    // 1. Verificar si el GPS está prendido
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(
        'Los servicios de ubicación están desactivados. Por favor actívalos.',
      );
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
        'Permisos de ubicación denegados permanentemente. Habilítalos en configuración.',
      );
    }

    // 3. Intentar obtener posición (Lógica de reintentos original)
    try {
      final primary = await tryGet(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );
      if (primary != null) return primary;
    } on TimeoutException {
      // Falló el primer intento, continuamos...
    } catch (_) {}

    try {
      final secondary = await tryGet(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 25),
      );
      if (secondary != null) return secondary;
    } on TimeoutException {
      // Falló el segundo intento, continuamos...
    } catch (_) {}

    // 4. Último recurso: última posición conocida
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;

    return Future.error('No se pudo obtener ubicación (sin señal GPS). Intenta de nuevo.');
  }

  /// Abrir configuración de la app
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}