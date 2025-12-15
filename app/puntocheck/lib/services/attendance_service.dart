import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/registros_asistencia.dart';
import 'supabase_client.dart';

class AttendanceService {
  AttendanceService._();
  static final instance = AttendanceService._();

  /// Ejecuta el RPC `realizar_checkin` definido en SQL.
  /// Maneja transacción, validación de geocerca y creación de registro en un solo paso.
  Future<Map<String, dynamic>> performCheckIn({
    required double lat,
    required double long,
    required String photoPath, // Path retornado por StorageService
    required String type, // 'entrada', 'salida', 'inicio_break', 'fin_break'
    String? sucursalId, // Opcional, si el usuario selecciona una manual
  }) async {
    try {
      final params = {
        'lat': lat,
        'long': long,
        'foto_url': photoPath,
        'tipo': type,
        'sucursal_id_input': sucursalId,
      };

      // Llamada a función RPC
      final response = await supabase.rpc('realizar_checkin', params: params);

      // El RPC retorna un JSON: { "success": true, "id": "...", "distancia": 10.5, "dentro_rango": true }
      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // Errores lanzados por RAISE EXCEPTION en Postgres (ej: "Usuario no encontrado")
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al marcar asistencia: $e');
    }
  }

  /// Obtener historial de asistencia del usuario actual
  Future<List<RegistrosAsistencia>> getMyHistory({int limit = 20}) async {
    try {
      final response = await supabase
          .from('registros_asistencia')
          .select()
          // RLS asegura que solo veo los míos, pero filtramos por si acaso
          .eq('perfil_id', supabase.auth.currentUser!.id)
          .order('fecha_hora_marcacion', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RegistrosAsistencia.fromDynamic(json))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo historial: $e');
    }
  }

  /// Obtener asistencia de HOY (para saber si ya marcó entrada)
  Future<RegistrosAsistencia?> getTodayLastRecord() async {
    try {
      final now = DateTime.now();
      // Inicio del día local (aprox, idealmente usar UTC o timestamp exacto)
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();

      final response = await supabase
          .from('registros_asistencia')
          .select()
          .eq('perfil_id', supabase.auth.currentUser!.id)
          .gte(
            'fecha_hora_marcacion',
            startOfDay,
          ) // Mayor o igual al inicio de hoy
          .order('fecha_hora_marcacion', ascending: false)
          .limit(1)
          .maybeSingle(); // Retorna null si no hay registros

      if (response == null) return null;
      return RegistrosAsistencia.fromDynamic(response);
    } catch (e) {
      throw Exception('Error verificando estado actual: $e');
    }
  }

  /// Obtener registros recientes por organizacion (soporte / super admin).
  Future<List<RegistrosAsistencia>> getRecentByOrg(String orgId, {int limit = 10}) async {
    try {
      final response = await supabase
          .from('registros_asistencia')
          .select()
          .eq('organizacion_id', orgId)
          .order('fecha_hora_marcacion', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RegistrosAsistencia.fromDynamic(json))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo asistencia reciente: $e');
    }
  }
}
