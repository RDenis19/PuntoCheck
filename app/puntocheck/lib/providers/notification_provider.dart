import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'core_providers.dart';

/// Stream de notificaciones en tiempo real
final myNotificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.myNotificationsStream;
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationController(this._ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    // Optimistic update podría ser complejo con StreamProvider, 
    // así que por ahora confiamos en que el backend actualice y el stream emita de nuevo.
    try {
      final service = _ref.read(notificationServiceProvider);
      await service.markAsRead(notificationId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final service = _ref.read(notificationServiceProvider);
      await service.markAllAsRead();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationControllerProvider = StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref);
});
