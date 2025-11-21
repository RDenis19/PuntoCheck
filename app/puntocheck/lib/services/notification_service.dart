import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream en tiempo real de mis notificaciones
  Stream<List<AppNotification>> get myNotificationsStream {
    final userId = _supabase.auth.currentUser!.id;
    
    // Escucha cambios en la tabla notifications
    // Nota: Para que stream funcione con filtros complejos (OR user_id is null),
    // a veces es mejor filtrar en cliente o usar una tabla "inbox".
    // Aquí usamos stream simple y filtramos por usuario directo.
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // Limitación: Stream no soporta 'OR' complex filters fácilmente aún
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  }

  /// Obtener notificaciones (Globales + Personales) vía REST (Más flexible que Stream)
  Future<List<AppNotification>> getNotifications() async {
    final userId = _supabase.auth.currentUser!.id;

    // Traemos notificaciones donde user_id es MÍO o NULL (Globales de la Org via RLS)
    // RLS ya filtra por organization_id, así que user_id IS NULL implica "Toda mi org"
    final response = await _supabase
        .from('notifications')
        .select()
        .or('user_id.eq.$userId,user_id.is.null')
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  /// Marcar como leída
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
  
  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
     final userId = _supabase.auth.currentUser!.id;
     await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}