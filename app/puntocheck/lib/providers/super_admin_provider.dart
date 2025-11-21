import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organization_model.dart';
import 'core_providers.dart';

// --- Providers de Lectura (SuperAdmin) ---

/// Obtiene todas las organizaciones registradas
final allOrganizationsProvider = FutureProvider.autoDispose<List<Organization>>((ref) async {
  final service = ref.watch(organizationServiceProvider);
  return await service.getAllOrganizations();
});

/// Estadísticas globales para SuperAdmin
final superAdminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(organizationServiceProvider);
  return await service.getSuperAdminStats();
});
