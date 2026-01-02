import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestión CRUD de plantillas de horarios
class ScheduleService {
  // Sin variable de instancia, usar supabase directamente

  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static ScheduleService get instance => _instance;

  Never _throwFriendlyScheduleError(PostgrestException e) {
    final haystack = <Object?>[
      e.message,
      e.details,
      e.hint,
    ].where((v) => v != null).map((v) => v.toString()).join(' ').toLowerCase();

    if (e.code == '42501') {
      throw Exception(
        'Sin permisos para gestionar horarios (revisa pol\u00edticas RLS).',
      );
    }

    final isOverlap =
        haystack.contains('validar_jornada_compleja') ||
        haystack.contains('overlap') ||
        haystack.contains('solap');

    if (isOverlap) {
      throw Exception(
        'Los turnos no pueden solaparse. Revisa las horas o marca "d\u00eda siguiente" cuando aplique.',
      );
    }

    throw Exception('Error en horarios: ${e.message}');
  }

  /// Obtiene todas las plantillas de horarios de una organización
  Future<List<PlantillasHorarios>> getScheduleTemplates(
    String organizacionId,
  ) async {
    try {
      final response = await supabase
          .from('plantillas_horarios')
          .select('''
            id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
            turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
            ''')
          .eq('organizacion_id', organizacionId)
          .or('eliminado.is.null,eliminado.eq.false')
          .order('creado_en', ascending: false);

      return response.map((e) => PlantillasHorarios.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al obtener plantillas de horarios: $e');
    }
  }

  Future<PlantillasHorarios> getScheduleTemplateById(String plantillaId) async {
    try {
      final response = await supabase
          .from('plantillas_horarios')
          .select('''
            id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
            turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
            ''')
          .eq('id', plantillaId)
          .single();

      return PlantillasHorarios.fromJson(response);
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al obtener plantilla: $e');
    }
  }

  /// Crea una nueva plantilla de horario
  Future<PlantillasHorarios> createScheduleTemplate({
    required String organizacionId,
    required String nombre,
    required List<Map<String, dynamic>>
    turnos, // cada uno: nombre_turno, hora_inicio, hora_fin, orden?, es_dia_siguiente?
    int toleranciaEntradaMinutos = 10,
    List<int> diasLaborales = const [1, 2, 3, 4, 5],
    bool esRotativo = false,
  }) async {
    try {
      if (turnos.isEmpty) {
        throw Exception('Debes agregar al menos un turno');
      }

      final plantilla = await supabase
          .from('plantillas_horarios')
          .insert({
            'organizacion_id': organizacionId,
            'nombre': nombre,
            'tolerancia_entrada_minutos': toleranciaEntradaMinutos,
            'dias_laborales': diasLaborales,
            'es_rotativo': esRotativo,
            'eliminado': false,
          })
          .select()
          .single();

      final turnosPayload = turnos.asMap().entries.map((entry) {
        final idx = entry.key;
        final t = Map<String, dynamic>.from(entry.value);
        t.putIfAbsent('nombre_turno', () => 'Turno ${idx + 1}');
        t['plantilla_id'] = plantilla['id'];
        t.putIfAbsent('orden', () => idx + 1);
        t.putIfAbsent('es_dia_siguiente', () => false);
        return t;
      }).toList();

      await supabase.from('turnos_jornada').insert(turnosPayload);

      // Recuperamos con turnos
      final full = await supabase
          .from('plantillas_horarios')
          .select('''
            id, organizacion_id, nombre, dias_laborales, tolerancia_entrada_minutos, es_rotativo, eliminado, creado_en,
            turnos_jornada (id, plantilla_id, nombre_turno, hora_inicio, hora_fin, orden, es_dia_siguiente, creado_en)
            ''')
          .eq('id', plantilla['id'])
          .single();

      return PlantillasHorarios.fromJson(full);
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al crear plantilla de horario: $e');
    }
  }

  /// Actualiza una plantilla de horario existente
  Future<void> updateScheduleTemplate({
    required String plantillaId,
    String? nombre,
    String? horaEntrada,
    String? horaSalida,
    int? toleranciaEntradaMinutos,
    List<int>? diasLaborales,
    bool? esRotativo,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (nombre != null) updateData['nombre'] = nombre;
      if (toleranciaEntradaMinutos != null) {
        updateData['tolerancia_entrada_minutos'] = toleranciaEntradaMinutos;
      }
      if (diasLaborales != null) updateData['dias_laborales'] = diasLaborales;
      if (esRotativo != null) updateData['es_rotativo'] = esRotativo;

      if (updateData.isEmpty) return;

      await supabase
          .from('plantillas_horarios')
          .update(updateData)
          .eq('id', plantillaId);

      // Opcional: actualizar el primer turno si se envían horas
      if (horaEntrada != null || horaSalida != null) {
        final turnoUpdate = <String, dynamic>{};
        if (horaEntrada != null) turnoUpdate['hora_inicio'] = horaEntrada;
        if (horaSalida != null) turnoUpdate['hora_fin'] = horaSalida;
        if (turnoUpdate.isNotEmpty) {
          await supabase
              .from('turnos_jornada')
              .update(turnoUpdate)
              .eq('plantilla_id', plantillaId)
              .eq('orden', 1);
        }
      }
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al actualizar plantilla de horario: $e');
    }
  }

  /// Elimina (soft delete) una plantilla de horario
  Future<void> deleteScheduleTemplate(String plantillaId) async {
    try {
      final updated = await supabase
          .from('plantillas_horarios')
          .update({'eliminado': true})
          .eq('id', plantillaId)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw Exception('Plantilla no encontrada o sin permisos');
      }
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al eliminar plantilla de horario: $e');
    }
  }

  Future<void> updateScheduleTurns({
    required String plantillaId,
    required List<Map<String, dynamic>> turnos,
  }) async {
    try {
      final existing = await supabase
          .from('turnos_jornada')
          .select('id')
          .eq('plantilla_id', plantillaId);

      final existingIds = (existing as List)
          .map((e) => e['id'].toString())
          .toSet();

      for (final t in turnos) {
        final id = t['id']?.toString();
        if (id == null || !existingIds.contains(id)) {
          throw Exception(
            'No se puede cambiar la cantidad de turnos desde editar. Crea una nueva plantilla si necesitas agregar/quitar turnos.',
          );
        }
      }

      for (final t in turnos) {
        final id = t['id'].toString();
        final updateData = <String, dynamic>{
          'nombre_turno': t['nombre_turno'],
          'hora_inicio': t['hora_inicio'],
          'hora_fin': t['hora_fin'],
          'orden': t['orden'],
          'es_dia_siguiente': t['es_dia_siguiente'],
        };
        await supabase.from('turnos_jornada').update(updateData).eq('id', id);
      }
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al actualizar turnos: $e');
    }
  }

  /// Obtiene el número de empleados asignados a una plantilla
  Future<int> getAssignedEmployeesCount(String plantillaId) async {
    try {
      final response = await supabase
          .from('asignaciones_horarios')
          .select()
          .eq('plantilla_id', plantillaId)
          .or(
            'fecha_fin.is.null,fecha_fin.gte.${DateTime.now().toIso8601String()}',
          );

      return (response as List).length;
    } on PostgrestException catch (e) {
      _throwFriendlyScheduleError(e);
    } catch (e) {
      throw Exception('Error al contar empleados asignados: $e');
    }
  }
}
