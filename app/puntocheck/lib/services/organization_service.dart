import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/organization_model.dart';

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
}