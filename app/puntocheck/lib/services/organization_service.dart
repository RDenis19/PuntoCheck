import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_model.dart';
import '../models/profile_model.dart';

class OrganizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la organización del usuario actual
  /// Usa la relación profiles -> organizations
  Future<Organization?> getMyOrganization() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Hacemos un join manual lógico: 
      // 1. Obtener org_id del perfil
      final profileData = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .single();
      
      final orgId = profileData['organization_id'];
      if (orgId == null) return null;

      // 2. Obtener datos de la org
      final orgData = await _supabase
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();

      return Organization.fromJson(orgData);
    } catch (e) {
      // Puede fallar si el usuario aún no tiene org asignada
      print('Error obteniendo organización: $e');
      return null;
    }
  }

  /// ADMIN: Actualiza la configuración de la empresa
  Future<void> updateConfig(String orgId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('organizations')
          .update(updates)
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error actualizando configuración: $e');
    }
  }

  /// SUPERADMIN: Obtiene todas las organizaciones
  Future<List<Organization>> getAllOrganizations() async {
    try {
      final data = await _supabase
          .from('organizations')
          .select()
          .order('created_at', ascending: false);
      
      return (data as List).map((e) => Organization.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando organizaciones: $e');
    }
  }

  /// SUPERADMIN: Obtiene estadísticas globales
  Future<Map<String, dynamic>> getSuperAdminStats() async {
    try {
      final orgsCount = await _supabase
          .from('organizations')
          .count(CountOption.exact);
      final usersCount = await _supabase
          .from('profiles')
          .count(CountOption.exact);
      
      return {
        'organizations': orgsCount,
        'users': usersCount,
        'active_plans': orgsCount, // Mock por ahora
      };
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  /// ADMIN: Obtiene empleados de una organización
  Future<List<Profile>> getEmployeesByOrg(String organizationId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);
      
      return (data as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando empleados: $e');
    }
  }

  /// ADMIN: Obtiene estadísticas del dashboard para una organización
  Future<Map<String, dynamic>> getAdminDashboardStats(String organizationId) async {
    try {
      // 1. Total empleados
      final totalEmployees = await _supabase
          .from('profiles')
          .count(CountOption.exact)
          .eq('organization_id', organizationId);
      
      // 2. Turnos activos ahora (gente trabajando)
      final activeShiftsResponse = await _supabase
          .from('work_shifts')
          .select('id, user_id, profiles!inner(organization_id)')
          .eq('profiles.organization_id', organizationId)
          .filter('check_out_time', 'is', null);
      
      final activeShifts = (activeShiftsResponse as List).length;
      
      return {
        'employees': totalEmployees,
        'active_shifts': activeShifts,
        'late_arrivals': 0, // TODO: Implementar lógica de atrasos
      };
    } catch (e) {
      throw Exception('Error obteniendo estadísticas de admin: $e');
    }
  }
}