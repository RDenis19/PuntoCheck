import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'package:state_notifier/state_notifier.dart';

// --- Providers de Lectura (Admin) ---

/// Obtiene la lista de empleados de la organización del usuario actual
final orgEmployeesProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null || userProfile.organizationId == null) return [];
  
  final service = ref.watch(organizationServiceProvider);
  return await service.getEmployeesByOrg(userProfile.organizationId!);
});

/// Obtiene estadísticas básicas para el Dashboard de Admin
final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userProfile = await ref.watch(currentUserProfileProvider.future);
  if (userProfile == null || userProfile.organizationId == null) {
    return {'employees': 0, 'active_shifts': 0, 'late_arrivals': 0};
  }
  
  final service = ref.watch(organizationServiceProvider);
  return await service.getAdminDashboardStats(userProfile.organizationId!);
});

// --- Controller (Admin) ---

class AdminController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AdminController(this._ref) : super(const AsyncValue.data(null));

  // TODO: Implementar creación de empleados
  Future<void> createEmployee(String email, String fullName, String jobTitle) async {
    // Placeholder
  }
}

final adminControllerProvider = StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  return AdminController(ref);
});
