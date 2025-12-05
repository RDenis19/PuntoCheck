import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/models/registro_asistencia_model.dart';

class AttendanceService {
  final SupabaseClient _supabase;

  AttendanceService(this._supabase);

  /// Ejecuta el procedimiento almacenado 'realizar_checkin' en PostgreSQL.
  ///
  /// Garantiza que la ubicación se guarde como tipo GEOGRAPHY(POINT) y
  /// valida la transacción de forma atómica en el servidor.
  ///
  /// [lat], [long]: Coordenadas decimales del GPS.
  /// [fotoPath]: Path relativo devuelto por StorageService (no la URL firmada).
  /// [tipo]: 'entrada', 'salida', 'inicio_break', 'fin_break'.
  Future<void> registrarMarcacion({
    required double lat,
    required double long,
    required String fotoPath,
    required String tipo,
  }) async {
    try {
      // RPC permite pasar argumentos como Map.
      // Los keys deben coincidir EXACTAMENTE con los argumentos de la función SQL.
      await _supabase.rpc(
        'realizar_checkin',
        params: {'lat': lat, 'long': long, 'foto_url': fotoPath, 'tipo': tipo},
      );
    } on PostgrestException catch (e) {
      // Manejo de errores de negocio definidos en el SQL (ej: Trigger raise exception)
      throw Exception('Error al marcar asistencia: ${e.message}');
    } catch (e) {
      throw Exception('Error de conexión o inesperado: $e');
    }
  }

  /// Obtiene el historial de registros del usuario actual en un rango de fechas.
  ///
  /// **Optimización Supabase v2:**
  /// Los filtros (.gte, .lte) deben aplicarse ANTES de .withConverter.
  /// Si usas .withConverter primero, obtienes un TransformBuilder que ya no acepta filtros SQL.
  Future<List<RegistroAsistenciaModel>> getHistorial({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      return await _supabase
          .from('registros_asistencia')
          .select() // Select inicial
          .eq(
            'perfil_id',
            userId,
          ) // Filtro explícito (aunque RLS protege, esto optimiza el index)
          .gte(
            'fecha_hora_marcacion',
            fechaInicio.toIso8601String(),
          ) // >= Fecha Inicio
          .lte(
            'fecha_hora_marcacion',
            fechaFin.toIso8601String(),
          ) // <= Fecha Fin
          .order('fecha_hora_marcacion', ascending: false) // Ordenamiento SQL
          .withConverter<List<RegistroAsistenciaModel>>(
            // Conversión final
            (data) =>
                data.map((e) => RegistroAsistenciaModel.fromJson(e)).toList(),
          );
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener historial: ${e.message}');
    }
  }

  /// Obtiene la última marcación del día para determinar el estado de la UI
  /// (ej: Si el último fue 'entrada', mostrar botón 'salida').
  Future<RegistroAsistenciaModel?> getUltimoEstado() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      return await _supabase
          .from('registros_asistencia')
          .select()
          .eq('perfil_id', userId)
          .order('fecha_hora_marcacion', ascending: false)
          .limit(1)
          .maybeSingle() // Retorna null si no hay registros, evita excepción 'Row not found'
          .withConverter<RegistroAsistenciaModel?>(
            (data) =>
                data == null ? null : RegistroAsistenciaModel.fromJson(data),
          );
    } catch (e) {
      // Log silencioso o rethrow según estrategia de monitoreo
      return null;
    }
  }
}
