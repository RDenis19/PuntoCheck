import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notificacion.dart';
import 'auditor_providers.dart';

final auditorNotificationsProvider =
    FutureProvider.autoDispose<List<Notificacion>>((ref) async {
  final orgId = await requireAuditorOrgId(ref);
  return ref.read(auditorServiceProvider).getMyNotifications(orgId: orgId, limit: 150);
});

final auditorUnreadNotificationsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final orgId = await requireAuditorOrgId(ref);
  return ref.read(auditorServiceProvider).getUnreadNotificationsCount(orgId: orgId);
});

class AuditorNotificationsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> markRead(String notificationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(auditorServiceProvider).markNotificationAsRead(notificationId),
    );
    if (!state.hasError) {
      ref
        ..invalidate(auditorNotificationsProvider)
        ..invalidate(auditorUnreadNotificationsCountProvider);
    }
  }

  Future<void> markAllRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final orgId = await requireAuditorOrgId(ref);
      await ref.read(auditorServiceProvider).markAllMyNotificationsAsRead(orgId: orgId);
    });
    if (!state.hasError) {
      ref
        ..invalidate(auditorNotificationsProvider)
        ..invalidate(auditorUnreadNotificationsCountProvider);
    }
  }
}

final auditorNotificationsControllerProvider =
    AsyncNotifierProvider<AuditorNotificationsController, void>(
  AuditorNotificationsController.new,
);

