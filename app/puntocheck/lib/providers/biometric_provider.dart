import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'core_providers.dart';

// --- Providers de Lectura ---

/// Verifica si la autenticación biométrica está disponible en el dispositivo
final isBiometricAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isBiometricAvailable();
});

// --- Controller ---

class BiometricController extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  BiometricController(this._ref) : super(const AsyncValue.data(false));

  /// Ejecuta la autenticación biométrica
  /// Retorna true si fue exitosa, false si falló o se canceló
  Future<bool> authenticate() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(biometricServiceProvider);
      final result = await service.authenticate();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final biometricControllerProvider = StateNotifierProvider<BiometricController, AsyncValue<bool>>((ref) {
  return BiometricController(ref);
});
