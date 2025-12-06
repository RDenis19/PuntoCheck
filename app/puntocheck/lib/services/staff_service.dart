import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfiles.dart';
import 'supabase_client.dart';

class StaffService {
  StaffService._();
  static final instance = StaffService._();

  /// Obtener lista de personal con búsqueda
  Future<List<Perfiles>> getStaff(String orgId, {String? searchQuery}) async {
    try {
      // 1. Iniciamos la construcción de la query (PostgrestFilterBuilder)
      var query = supabase
          .from('perfiles')
          .select()
          .eq('organizacion_id', orgId)
          .eq('eliminado', false);

      // 2. Aplicamos el filtro condicional usando .filter()
      // Sintaxis Dart: .filter('columna', 'operador', 'valor')
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.filter('apellidos', 'ilike', '%$searchQuery%');
      }

      // 3. Ordenamos y ejecutamos
      // Nota: .order() transforma el Builder, por eso se hace al final
      final response = await query.order('apellidos', ascending: true);

      return (response as List).map((e) => Perfiles.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error cargando personal: $e');
    }
  }

  /// Obtener perfil específico (Detalle empleado)
  Future<Perfiles> getProfile(String userId) async {
    try {
      final response = await supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();
      return Perfiles.fromJson(response);
    } catch (e) {
      throw Exception('Error cargando perfil: $e');
    }
  }

  /// Crear Perfil (Registro en DB)
  Future<void> createProfileRecord(Perfiles perfil) async {
    try {
      final data = perfil.toJson();
      // data['id'] debe venir del Auth User creado previamente por Admin
      await supabase.from('perfiles').insert(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('El usuario ya tiene un perfil registrado.');
      }
      if (e.code == '42501') {
        throw Exception(
          'Sin permisos para crear perfiles (revisa políticas RLS).',
        );
      }
      throw Exception('Error creando perfil: ${e.message}');
    } catch (e) {
      throw Exception('Error creando perfil: $e');
    }
  }

  /// Actualizar Perfil (Rol, Cargo, Jefe)
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await supabase.from('perfiles').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  /// Dar de baja (Soft Delete)
  Future<void> dismissEmployee(String userId) async {
    try {
      await supabase
          .from('perfiles')
          .update({'activo': false, 'eliminado': true})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error dando de baja: $e');
    }
  }

  /// Asignar Horario
  Future<void> assignSchedule({
    required String perfilId,
    required String orgId,
    required String plantillaId,
    required DateTime fechaInicio,
  }) async {
    try {
      await supabase.from('asignaciones_horarios').insert({
        'perfil_id': perfilId,
        'organizacion_id': orgId,
        'plantilla_id': plantillaId,
        'fecha_inicio': fechaInicio.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error asignando horario: $e');
    }
  }
}
