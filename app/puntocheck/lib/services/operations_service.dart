import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/registros_asistencia.dart';
import 'supabase_client.dart';

class OperationsService {
  OperationsService._();
  static final instance = OperationsService._();

  // ---------------------------------------------------------------------------
  // MARCACIÓN (RPC) - Employee
  // ---------------------------------------------------------------------------

  /// Ejecuta RPC 'realizar_checkin'
  /// Retorna Map con {success, id, distancia, dentro_rango}
  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double long,
    required String photoPath,
    required String type, // 'entrada', 'salida', 'inicio_break', 'fin_break'
    String? sucursalId,
  }) async {
    try {
      final response = await supabase.rpc(
        'realizar_checkin',
        params: {
          'lat': lat,
          'long': long,
          'foto_url': photoPath,
          'tipo': type,
          'sucursal_id_input': sucursalId,
        },
      );
      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // Captura errores de negocio lanzados por Postgres (ej: "Usuario no encontrado")
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error de conexión al marcar: $e');
    }
  }

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
      var query = supabase.from('registros_asistencia').select();

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

      final response = await query
          .order('fecha_hora_marcacion', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => RegistrosAsistencia.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error cargando historial: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MODO KIOSCO (Manager / Org Admin)
  // ---------------------------------------------------------------------------

  /// Generar Token QR para modo Kiosco
  Future<String> generateKioskQrToken(String sucursalId, String orgId) async {
    try {
      // Generamos un hash simple temporal (en prod usar librería uuid o crypto)
      final tokenHash = 'QR-${DateTime.now().millisecondsSinceEpoch}';

      await supabase.from('qr_codigos_temporales').insert({
        'sucursal_id': sucursalId,
        'organizacion_id': orgId,
        'token_hash': tokenHash,
        'fecha_expiracion': DateTime.now()
            .add(const Duration(minutes: 5))
            .toIso8601String(),
        'creado_por_id': supabase.auth.currentUser!.id,
        'es_valido': true,
      });

      return tokenHash;
    } catch (e) {
      throw Exception('Error generando QR: $e');
    }
  }
}
