import '../models/organizaciones.dart';
import '../models/sucursales.dart';
import '../models/plantillas_horarios.dart';
import 'supabase_client.dart';

class OrganizationService {
  OrganizationService._();
  static final instance = OrganizationService._();

  // ---------------------------------------------------------------------------
  // CONFIGURACIÓN DE EMPRESA
  // ---------------------------------------------------------------------------

  /// Obtener datos de mi organización
  Future<Organizaciones> getMyOrganization(String orgId) async {
    try {
      final response = await supabase
          .from('organizaciones')
          .select()
          .eq('id', orgId)
          .single();
      return Organizaciones.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando organización: $e');
    }
  }

  /// Actualizar reglas legales (Tolerancias, horas extras) - (Org Admin)
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
      throw Exception('Error actualizando configuración legal: $e');
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
}
