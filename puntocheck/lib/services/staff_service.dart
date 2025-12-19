import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/encargados_sucursales.dart';
import '../models/perfiles.dart';
import 'supabase_client.dart';

class StaffService {
  StaffService._();
  static final instance = StaffService._();

  Never _throwFriendlyProfileWriteError(PostgrestException e) {
    final haystack = <Object?>[
      e.message,
      e.details,
      e.hint,
    ].where((v) => v != null).map((v) => v.toString()).join(' ').toLowerCase();

    final isPlanLimit =
        haystack.contains('check_cupo_plan') ||
        haystack.contains('max_usuarios') ||
        haystack.contains('max usuarios') ||
        haystack.contains('limite de usuarios') ||
        haystack.contains('límite de usuarios') ||
        haystack.contains('cupo plan') ||
        (haystack.contains('cupo') && haystack.contains('plan')) ||
        (haystack.contains('plan') && haystack.contains('usuarios'));

    if (isPlanLimit) {
      throw Exception(
        'No se pudo crear el usuario: tu plan alcanzó el límite de usuarios. '
        'Desactiva/elimina usuarios o actualiza tu plan.',
      );
    }

    if (e.code == '23505') {
      throw Exception(
        'No se pudo crear el usuario: ya existe un perfil con esos datos.',
      );
    }

    if (e.code == '42501') {
      throw Exception(
        'Sin permisos para crear perfiles (revisa políticas RLS).',
      );
    }

    throw Exception('Error guardando perfil: ${e.message}');
  }

  /// Obtener lista de personal con búsqueda.
  /// El orden por defecto es por fecha de creación (desc) para priorizar ingresos recientes.
  Future<List<Perfiles>> getStaff(
    String orgId, {
    String? searchQuery,
    String orderBy = 'creado_en',
    bool ascending = false,
  }) async {
    try {
      var query = supabase
          .from('perfiles')
          .select()
          .eq('organizacion_id', orgId)
          .or('eliminado.is.null,eliminado.eq.false');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final sq = searchQuery.trim();
        query = query.or('apellidos.ilike.%$sq%,nombres.ilike.%$sq%');
      }

      final response = await query.order(orderBy, ascending: ascending);
      return (response as List).map((e) => Perfiles.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw Exception(
          'Sin permisos para ver el equipo (RLS en perfiles). Verifica la policy para super_admin.',
        );
      }
      throw Exception('Error cargando personal: ${e.message}');
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
          .maybeSingle();
      if (response == null) {
        throw Exception('Perfil no encontrado');
      }
      return Perfiles.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error cargando perfil: ${e.message}');
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
      _throwFriendlyProfileWriteError(e);
    } catch (e) {
      throw Exception('Error creando perfil: $e');
    }
  }

  /// Actualizar Perfil (Rol, Cargo, Sucursal)
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = Map<String, dynamic>.from(updates)
        ..remove('correo')
        ..remove('email')
        ..removeWhere((key, value) => value == null);
      await supabase.from('perfiles').update(data).eq('id', userId);
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

  /// Crea un perfil ligado a un usuario ya creado en Auth.
  /// Solo roles manager, auditor o employee.
  Future<void> createOrgProfile({
    required String userId,
    required String orgId,
    required String nombres,
    required String apellidos,
    required RolUsuario rol,
    String? cedula,
    String? telefono,
    String? cargo,
    String? sucursalId,
  }) async {
    final data = {
      'id': userId,
      'organizacion_id': orgId,
      'nombres': nombres,
      'apellidos': apellidos,
      'rol': rol.value,
      'cedula': cedula,
      'telefono': telefono,
      'cargo': cargo,
      'sucursal_id': sucursalId,
      'activo': true,
      'eliminado': false,
    }..removeWhere((key, value) => value == null);

    try {
      await supabase.from('perfiles').insert(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Si el trigger `handle_new_user` ya creó el perfil, lo actualizamos.
        final updates = Map<String, dynamic>.from(data)
          ..remove('id')
          ..removeWhere((key, value) => value == null);
        await supabase.from('perfiles').update(updates).eq('id', userId);
        return;
      }
      if (e.code == '42501') {
        throw Exception(
          'Sin permisos para crear perfiles (revisa políticas RLS).',
        );
      }
      _throwFriendlyProfileWriteError(e);
    } catch (e) {
      throw Exception('Error creando perfil: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ENCARGADOS DE SUCURSAL
  // ---------------------------------------------------------------------------

  Future<List<EncargadosSucursales>> getBranchManagers(String branchId) async {
    try {
      final response = await supabase
          .from('encargados_sucursales')
          .select('''
            id, sucursal_id, manager_id, activo, creado_en,
            perfiles:manager_id (id, nombres, apellidos, organizacion_id, rol, sucursal_id)
            ''')
          .eq('sucursal_id', branchId)
          .or('activo.is.null,activo.eq.true');

      return (response as List)
          .map(
            (e) => EncargadosSucursales.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Error cargando encargados de sucursal: $e');
    }
  }

  Future<void> assignBranchManager({
    required String branchId,
    required String managerId,
  }) async {
    try {
      // Si ya existe, reactivar en lugar de duplicar para evitar violar unique constraints.
      final existing = await supabase
          .from('encargados_sucursales')
          .select('id')
          .eq('sucursal_id', branchId)
          .eq('manager_id', managerId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('encargados_sucursales')
            .update({'activo': true})
            .eq('id', existing['id']);
        return;
      }

      await supabase.from('encargados_sucursales').insert({
        'sucursal_id': branchId,
        'manager_id': managerId,
        'activo': true,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Ese perfil ya esta asignado como encargado en esta sucursal.',
        );
      }
      throw Exception('Error asignando encargado: ${e.message}');
    } catch (e) {
      throw Exception('Error asignando encargado: $e');
    }
  }

  Future<List<EncargadosSucursales>> getBranchManagersForBranches(
    List<String> branchIds,
  ) async {
    if (branchIds.isEmpty) return const [];
    try {
      final response = await supabase
          .from('encargados_sucursales')
          .select('''
            id, sucursal_id, manager_id, activo, creado_en,
            perfiles:manager_id (id, nombres, apellidos, organizacion_id, rol, sucursal_id)
            ''')
          .inFilter('sucursal_id', branchIds)
          .or('activo.is.null,activo.eq.true');

      return (response as List)
          .map(
            (e) => EncargadosSucursales.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Error cargando encargados: $e');
    }
  }

  /// Sincroniza encargados activos de una sucursal con el set deseado.
  /// - Inserta o reactiva para ids presentes.
  /// - Desactiva (activo=false) los que ya no esten.
  Future<void> setBranchManagers({
    required String branchId,
    required Set<String> managerIds,
  }) async {
    try {
      final existing = await supabase
          .from('encargados_sucursales')
          .select('id, manager_id, activo')
          .eq('sucursal_id', branchId);

      final rows = List<Map<String, dynamic>>.from(existing as List);
      final Map<String, Map<String, dynamic>> byManagerId = {
        for (final r in rows) (r['manager_id'] as String): r,
      };

      final Set<String> activeManagerIds = {
        for (final r in rows)
          if (r['activo'] != false) (r['manager_id'] as String),
      };

      final toActivate = managerIds.difference(activeManagerIds);
      final toDeactivate = activeManagerIds.difference(managerIds);

      for (final managerId in toActivate) {
        final row = byManagerId[managerId];
        if (row != null) {
          await supabase
              .from('encargados_sucursales')
              .update({'activo': true})
              .eq('id', row['id']);
        } else {
          await supabase.from('encargados_sucursales').insert({
            'sucursal_id': branchId,
            'manager_id': managerId,
            'activo': true,
          });
        }
      }

      for (final managerId in toDeactivate) {
        final row = byManagerId[managerId];
        if (row == null) continue;
        await supabase
            .from('encargados_sucursales')
            .update({'activo': false})
            .eq('id', row['id']);
      }
    } catch (e) {
      throw Exception('Error sincronizando encargados: $e');
    }
  }

  Future<void> deactivateBranchManager(String assignmentId) async {
    try {
      await supabase
          .from('encargados_sucursales')
          .update({'activo': false})
          .eq('id', assignmentId);
    } catch (e) {
      throw Exception('Error desactivando encargado: $e');
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
