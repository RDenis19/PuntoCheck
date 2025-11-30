import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream en tiempo real de notificaciones (usuario + organización).
  Stream<List<AppNotification>> myNotificationsStream({String? orgId}) {
    final userId = _supabase.auth.currentUser!.id;

    final stream = orgId != null
        ? _supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('organization_id', orgId)
            .order('created_at', ascending: false)
        : _supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false);

    return stream
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  /// Obtener notificaciones (Globales + Personales) via REST.
  Future<List<AppNotification>> getNotifications() async {
    final userId = _supabase.auth.currentUser!.id;
    final orgId = await _currentOrganizationId();

    final response = await _supabase
        .from('notifications')
        .select()
        .or('user_id.eq.$userId,organization_id.eq.$orgId')
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Crea un anuncio para la organización (visible para todos en la org).
  Future<void> createAnnouncement({
    required String organizationId,
    required String title,
    required String body,
    NotifType type = NotifType.info,
  }) async {
    await _supabase.from('notifications').insert({
      'title': title,
      'body': body,
      'type': type.toJson(),
      'organization_id': organizationId,
      'user_id': _supabase.auth.currentUser?.id,
      'is_read': false,
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String organizationId,
    required String title,
    required String body,
    NotifType type = NotifType.info,
  }) async {
    await _supabase
        .from('notifications')
        .update({
          'title': title,
          'body': body,
          'type': type.toJson(),
        })
        .eq('id', id)
        .eq('organization_id', organizationId);
  }

  Future<void> deleteAnnouncement({
    required String id,
    required String organizationId,
  }) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', id)
        .eq('organization_id', organizationId);
  }

  Future<String?> _currentOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .maybeSingle();
    return data?['organization_id'] as String?;
  }
}
