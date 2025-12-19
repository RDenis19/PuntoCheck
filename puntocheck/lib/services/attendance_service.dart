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
