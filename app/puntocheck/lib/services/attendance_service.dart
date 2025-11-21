import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_shift_model.dart';
import '../models/geo_location.dart';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene el historial de asistencia del usuario actual
  /// [limit] controla cuántos registros traer para el feed inicial
  Future<List<WorkShift>> getMyHistory({int limit = 20}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final response = await _supabase
          .from('work_shifts')
          .select() // SELECT * trae location como GeoJSON automáticamente en versiones nuevas
          .eq('user_id', userId)
          .order('date', ascending: false)
          .order('check_in_time', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => WorkShift.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo historial: $e');
    }
  }

  /// Busca si hay un turno activo hoy (check_out_time es NULL)
  Future<WorkShift?> getActiveShift() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final data = await _supabase
          .from('work_shifts')
          .select()
          .eq('user_id', userId)
          .isFilter('check_out_time', null) // Busca donde NO haya salida
          .maybeSingle(); // Retorna null si no hay registros

      if (data == null) return null;
      return WorkShift.fromJson(data);
    } catch (e) {
      throw Exception('Error verificando turno activo: $e');
    }
  }

  /// Registra ENTRADA (Check-In)
  Future<void> checkIn({
    required GeoLocation location,
    required String photoPath, // Path relativo del Storage
    String? address,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Nota: No enviamos organization_id, el Trigger en DB lo pone automático.
    // Usamos toInsertJson del modelo para formatear PostGIS correctamente.
    final shift = WorkShift(
      id: '', // DB genera UUID
      organizationId: '', // Trigger lo llena
      userId: user.id,
      date: DateTime.now(), // DB usa CURRENT_DATE, pero modelo requiere dato
      checkInTime: DateTime.now(),
      checkInLocation: location,
      checkInPhotoUrl: photoPath,
      checkInAddress: address,
    );

    try {
      await _supabase.from('work_shifts').insert(shift.toInsertJson());
    } catch (e) {
      throw Exception('Error marcando entrada: $e');
    }
  }

  /// Registra SALIDA (Check-Out)
  Future<void> checkOut({
    required String shiftId,
    required GeoLocation location,
    String? photoPath,
    String? address,
  }) async {
    // Preparamos solo los campos de salida
    final updateData = {
      'check_out_time': DateTime.now().toIso8601String(),
      'check_out_location': location.toJson(), // GeoJSON
      'check_out_photo_url': photoPath,
      'check_out_address': address,
    };

    try {
      await _supabase
          .from('work_shifts')
          .update(updateData)
          .eq('id', shiftId);
    } catch (e) {
      throw Exception('Error marcando salida: $e');
    }
  }

  /// Obtiene estadísticas básicas (para la tarjeta de "Hoy")
  /// Calcula localmente o llama a una vista RPC si la creaste
  Future<Map<String, dynamic>> getTodayStats() async {
    // Implementación simple: traer shifts de hoy
    final userId = _supabase.auth.currentUser!.id;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('work_shifts')
        .select('duration_minutes')
        .eq('user_id', userId)
        .eq('date', today);
    
    int totalMinutes = 0;
    for (var item in response) {
      totalMinutes += (item['duration_minutes'] as int?) ?? 0;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return {
      'hours': hours,
      'minutes': minutes,
      'shift_count': response.length,
    };
  }
}