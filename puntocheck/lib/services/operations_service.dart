import '../models/registros_asistencia.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class OperationsService {
  OperationsService._();
  static final instance = OperationsService._();

  static const _attendanceSelectWithJoins =
      '*, perfiles(nombres, apellidos), sucursales(nombre), turnos_jornada(nombre_turno, hora_inicio, hora_fin)';

  // ---------------------------------------------------------------------------
  // HISTORIAL DE ASISTENCIA
  // ---------------------------------------------------------------------------

  /// Obtener registros.
  /// - Si `targetUserId` es null: Trae registros propios (si es employee) o todos (si es admin/manager según RLS).
  /// - Filtros de fecha opcionales.
  Future<List<RegistrosAsistencia>> getAttendanceLogs({
    String? targetUserId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = supabase
          .from('registros_asistencia')
          .select(_attendanceSelectWithJoins);

      if (targetUserId != null) {
        query = query.eq('perfil_id', targetUserId);
      } else {
        // Si no especifico target, RLS decide.
        // Un Employee solo verá los suyos. Un Manager verá los de su org/equipo.
      }

      if (startDate != null) {
        query = query.gte('fecha_hora_marcacion', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('fecha_hora_marcacion', endDate.toIso8601String());
      }

      late final List<dynamic> rows;
      try {
        final response = await query
            .order('fecha_hora_marcacion', ascending: false)
            .limit(limit);
        rows = response as List<dynamic>;
      } on PostgrestException {
        var fallbackQuery = supabase.from('registros_asistencia').select('*');

        if (targetUserId != null) {
          fallbackQuery = fallbackQuery.eq('perfil_id', targetUserId);
        }
        if (startDate != null) {
          fallbackQuery = fallbackQuery.gte(
            'fecha_hora_marcacion',
            startDate.toIso8601String(),
          );
        }
        if (endDate != null) {
          fallbackQuery = fallbackQuery.lte(
            'fecha_hora_marcacion',
            endDate.toIso8601String(),
          );
        }

        final response = await fallbackQuery
            .order('fecha_hora_marcacion', ascending: false)
            .limit(limit);
        rows = response as List<dynamic>;
      }

      return rows.map(RegistrosAsistencia.fromDynamic).toList();
    } catch (e) {
      throw Exception('Error cargando historial: $e');
    }
  }
}
