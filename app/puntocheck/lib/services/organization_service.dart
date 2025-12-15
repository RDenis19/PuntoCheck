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
    DateTime? endDate,
  }) async {
    try {
      await supabase
          .from('organizaciones')
          .update({
            'plan_id': planId,
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
          .select(
            'id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros, tiene_qr_habilitado, device_id_qr_asignado, eliminado, creado_en',
          )
          .eq('organizacion_id', orgId)
          .or('eliminado.is.null,eliminado.eq.false');
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

      final orgId = data['organizacion_id'] as String?;
      if (orgId == null || orgId.isEmpty) {
        throw Exception(
          'Falta organization_id al crear la sucursal. Asegura cargar la organizacion antes de guardar.',
        );
      }

      // Convertimos GeoJSON a WKT si viene como mapa.
      final geo = sucursal.ubicacionCentral;
      if (geo != null &&
          geo['coordinates'] is List &&
          geo['coordinates'].length == 2) {
        final coords = geo['coordinates'] as List;
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        data['ubicacion_central'] = 'SRID=4326;POINT($lon $lat)';
      }

      // Asegura radio_metros numérico.
      if (data['radio_metros'] == null && sucursal.radioMetros != null) {
        data['radio_metros'] = sucursal.radioMetros;
      }

      // Evita enviar nulls innecesarios al insert.
      data.removeWhere((_, v) => v == null);

      await supabase.from('sucursales').insert(data);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        // RLS sin permisos
        throw Exception(
          'No tienes permisos para crear sucursales. Revisa las policies RLS para org_admin sobre la tabla sucursales.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('Error creando sucursal: $e');
    }
  }

  /// Obtener sucursales bajo RLS (sin filtrar por orgId explícito).
  Future<List<Sucursales>> getBranchesRls() async {
    try {
      final response = await supabase
          .from('sucursales')
          .select(
            'id, nombre, direccion, organizacion_id, ubicacion_central, radio_metros, tiene_qr_habilitado, device_id_qr_asignado, eliminado, creado_en',
          )
          .or('eliminado.is.null,eliminado.eq.false');
      return (response as List).map((e) => Sucursales.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error obteniendo sucursales: $e');
    }
  }

  /// Obtiene la sucursal vinculada a este dispositivo (kiosko).
  /// Busca por `device_id_qr_asignado` y devuelve null si no existe.
  ///
  /// Nota: si existen múltiples sucursales con el mismo device id, lanza error
  /// para forzar corrección en la configuración.
  Future<Sucursales?> getBranchByAssignedDeviceId(String deviceId) async {
    final id = deviceId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await supabase
          .from('sucursales')
          .select(
            'id, organizacion_id, nombre, direccion, ubicacion_central, radio_metros, tiene_qr_habilitado, device_id_qr_asignado, eliminado, creado_en',
          )
          .eq('device_id_qr_asignado', id)
          .or('eliminado.is.null,eliminado.eq.false')
          .limit(2);

      final rows = List<Map<String, dynamic>>.from(response as List);
      if (rows.isEmpty) return null;
      if (rows.length > 1) {
        throw Exception(
          'Hay más de una sucursal configurada con este Device ID. Debe ser único.',
        );
      }
      return Sucursales.fromJson(rows.first);
    } catch (e) {
      throw Exception('Error obteniendo sucursal por Device ID: $e');
    }
  }

  /// Actualizar sucursal (Org Admin/Super Admin según RLS).
  Future<void> updateBranch(Sucursales branch) async {
    try {
      final updates = <String, dynamic>{};

      updates['nombre'] = branch.nombre;
      updates['direccion'] = branch.direccion;

      if (branch.radioMetros != null) {
        updates['radio_metros'] = branch.radioMetros;
      }

      if (branch.tieneQrHabilitado != null) {
        updates['tiene_qr_habilitado'] = branch.tieneQrHabilitado;
        updates['device_id_qr_asignado'] = branch.tieneQrHabilitado == true
            ? branch.deviceIdQrAsignado
            : null;
      } else if (branch.deviceIdQrAsignado != null) {
        updates['device_id_qr_asignado'] = branch.deviceIdQrAsignado;
      }

      final geo = branch.ubicacionCentral;
      if (geo != null &&
          geo['coordinates'] is List &&
          geo['coordinates'].length == 2) {
        final coords = geo['coordinates'] as List;
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        updates['ubicacion_central'] = 'SRID=4326;POINT($lon $lat)';
      }

      if (updates.isEmpty) return;

      await supabase.from('sucursales').update(updates).eq('id', branch.id);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception(
          'No tienes permisos para actualizar sucursales. Revisa las policies RLS.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('Error actualizando sucursal: $e');
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
