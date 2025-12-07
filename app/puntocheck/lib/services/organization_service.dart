import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/plantillas_horarios.dart';
import '../models/sucursales.dart';
import 'supabase_client.dart';

class OrganizationService {
  OrganizationService._();
  static final instance = OrganizationService._();

  // ---------------------------------------------------------------------------
  // CONFIGURACION DE EMPRESA
  // ---------------------------------------------------------------------------

  /// Obtener datos de mi organizacion (Org Admin).
  Future<Organizaciones> getMyOrganization(String orgId) async {
    try {
      final response = await supabase
          .from('organizaciones')
          .select()
          .eq('id', orgId)
          .single();
      return Organizaciones.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando organizacion: $e');
    }
  }

  /// Obtener organizacion por id (Super Admin / soporte cross-org).
  Future<Organizaciones> getOrganizationById(String orgId) async {
    try {
      final response = await supabase
          .from('organizaciones')
          .select()
          .eq('id', orgId)
          .single();
      return Organizaciones.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando organizacion: $e');
    }
  }

  /// Actualizar reglas legales (Tolerancias, horas extras) - (Org Admin).
  Future<void> updateLegalConfig(
    String orgId,
    Map<String, dynamic> config,
  ) async {
    try {
      await supabase
          .from('organizaciones')
          .update({'configuracion_legal': config})
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error actualizando configuracion legal: $e');
    }
  }

  /// Actualiza branding (logo y paleta) preservando configuracion existente.
  Future<void> updateBranding({
    required String orgId,
    String? logoUrl,
    String? primaryHex,
    String? secondaryHex,
  }) async {
    try {
      final orgResponse = await supabase
          .from('organizaciones')
          .select('configuracion_legal, logo_url')
          .eq('id', orgId)
          .single();

      final currentConfig = Map<String, dynamic>.from(
        orgResponse['configuracion_legal'] ?? {},
      );
      final branding = Map<String, dynamic>.from(
        currentConfig['branding'] ?? {},
      );

      if (primaryHex != null) branding['primary'] = primaryHex;
      if (secondaryHex != null) branding['secondary'] = secondaryHex;
      branding['updated_at'] = DateTime.now().toIso8601String();

      currentConfig['branding'] = branding;

      await supabase
          .from('organizaciones')
          .update({
            'logo_url': logoUrl ?? orgResponse['logo_url'],
            'configuracion_legal': currentConfig,
          })
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error actualizando branding: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PLAN Y ESTADO DE SUSCRIPCION
  // ---------------------------------------------------------------------------

  Future<void> assignPlan({
    required String orgId,
    required String planId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await supabase
          .from('organizaciones')
          .update({
            'plan_id': planId,
            if (startDate != null)
              'fecha_inicio_suscripcion': startDate.toIso8601String(),
            if (endDate != null)
              'fecha_fin_suscripcion': endDate.toIso8601String(),
          })
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error asignando plan: $e');
    }
  }

  Future<void> updateSubscriptionStatus(
    String orgId,
    EstadoSuscripcion estado,
  ) async {
    try {
      await supabase
          .from('organizaciones')
          .update({'estado_suscripcion': estado.value})
          .eq('id', orgId);
    } catch (e) {
      throw Exception('Error actualizando estado de suscripcion: $e');
    }
  }

  /// Actualiza datos básicos de la organización (nombre, RUC, logo, plan).
  Future<void> updateOrganization({
    required String orgId,
    String? ruc,
    String? razonSocial,
    String? logoUrl,
    String? planId,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (ruc != null) updates['ruc'] = ruc;
      if (razonSocial != null) updates['razon_social'] = razonSocial;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (planId != null) updates['plan_id'] = planId;
      if (updates.isEmpty) return;

      await supabase.from('organizaciones').update(updates).eq('id', orgId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('RUC ya registrado. Usa otro RUC.');
      }
      throw Exception('Error actualizando organización: ${e.message}');
    } catch (e) {
      throw Exception('Error actualizando organización: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SUCURSALES (GEOFENCING)
  // ---------------------------------------------------------------------------

  Future<List<Sucursales>> getBranches(String orgId) async {
    try {
      final response = await supabase
          .from('sucursales')
          .select()
          .eq('organizacion_id', orgId)
          .eq('eliminado', false);
      return (response as List).map((e) => Sucursales.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error obteniendo sucursales: $e');
    }
  }

  /// Crear Sucursal (Org Admin)
  /// `ubicacionCentral`: Map GeoJSON {'type': 'Point', 'coordinates': [lon, lat]}
  Future<void> createBranch(Sucursales sucursal) async {
    try {
      final data = sucursal.toJson();
      data.remove('id');
      data.remove('creado_en');
      await supabase.from('sucursales').insert(data);
    } catch (e) {
      throw Exception('Error creando sucursal: $e');
    }
  }

  Future<void> deleteBranch(String branchId) async {
    try {
      // Soft Delete
      await supabase
          .from('sucursales')
          .update({'eliminado': true})
          .eq('id', branchId);
    } catch (e) {
      throw Exception('Error eliminando sucursal: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PLANTILLAS DE HORARIOS
  // ---------------------------------------------------------------------------

  Future<List<PlantillasHorarios>> getSchedules(String orgId) async {
    try {
      final response = await supabase
          .from('plantillas_horarios')
          .select()
          .eq('organizacion_id', orgId)
          .eq('eliminado', false);
      return (response as List)
          .map((e) => PlantillasHorarios.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo horarios: $e');
    }
  }

  Future<void> createSchedule(PlantillasHorarios plantilla) async {
    try {
      final data = plantilla.toJson();
      data.remove('id');
      data.remove('creado_en');
      await supabase.from('plantillas_horarios').insert(data);
    } catch (e) {
      throw Exception(
        'Error creando horario: $e',
      ); // El trigger DB valida legalidad (12h max)
    }
  }

  // ---------------------------------------------------------------------------
  // CREACION DE ORGANIZACION + ADMIN (Super Admin)
  // ---------------------------------------------------------------------------

  Future<Organizaciones> createOrganization({
    required String ruc,
    required String razonSocial,
    required String planId,
    EstadoSuscripcion estado = EstadoSuscripcion.prueba,
    String? logoUrl,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      final response = await supabase
          .from('organizaciones')
          .insert({
            'ruc': ruc,
            'razon_social': razonSocial,
            'plan_id': planId,
            'estado_suscripcion': estado.value,
            'logo_url': logoUrl,
            'creado_en': now,
            'actualizado_en': now,
          })
          .select()
          .single();

      return Organizaciones.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('RUC ya registrado. Usa otro RUC.');
      }
      throw Exception('Error creando organización: ${e.message}');
    } catch (e) {
      throw Exception('Error creando organización: $e');
    }
  }

  /// Crea una organización y su perfil admin asociado.
  /// - `adminUserId` debe existir en `auth.users`.
  /// - Asigna plan y estado inicial.
  Future<Organizaciones> createOrganizationWithAdmin({
    required String ruc,
    required String razonSocial,
    required String adminUserId,
    required String adminNombres,
    required String adminApellidos,
    required String planId,
    EstadoSuscripcion estado = EstadoSuscripcion.prueba,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      // 1) Insertar organización
      final orgInsert = await supabase
          .from('organizaciones')
          .insert({
            'ruc': ruc,
            'razon_social': razonSocial,
            'plan_id': planId,
            'estado_suscripcion': estado.value,
            'creado_en': now,
            'actualizado_en': now,
          })
          .select()
          .single();

      final org = Organizaciones.fromJson(orgInsert);

      // 2) Crear perfil admin ligado a la organización
      await supabase.from('perfiles').insert({
        'id': adminUserId,
        'organizacion_id': org.id,
        'nombres': adminNombres,
        'apellidos': adminApellidos,
        'rol': RolUsuario.orgAdmin.value,
        'activo': true,
        'eliminado': false,
      });

      return org;
    } catch (e) {
      throw Exception('Error creando organización y admin: $e');
    }
  }
}
