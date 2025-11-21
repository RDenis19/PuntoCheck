import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/organization_model.dart';
import 'core_providers.dart';

/// Organización del usuario actual
final myOrganizationProvider = FutureProvider<Organization?>((ref) async {
  final service = ref.watch(organizationServiceProvider);
  return await service.getMyOrganization();
});

// --- Controller (Admin) ---

class OrganizationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  OrganizationController(this._ref) : super(const AsyncValue.data(null));

  /// ADMIN: Actualiza la configuración de la organización
  Future<void> updateConfig(String orgId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(organizationServiceProvider);
      await service.updateConfig(orgId, updates);
      
      // Invalidar el provider de organización para refrescar los datos
      _ref.invalidate(myOrganizationProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final organizationControllerProvider = StateNotifierProvider<OrganizationController, AsyncValue<void>>((ref) {
  return OrganizationController(ref);
});
