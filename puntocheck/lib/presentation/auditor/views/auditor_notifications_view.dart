import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/presentation/admin/widgets/notification_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/auditor_notifications_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorNotificationsView extends ConsumerWidget {
  const AuditorNotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(auditorNotificationsProvider);
    final unreadCountAsync = ref.watch(auditorUnreadNotificationsCountProvider);
    final controllerAsync = ref.watch(auditorNotificationsControllerProvider);

    final unread = unreadCountAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: 'Marcar todas como leídas',
              onPressed: controllerAsync.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(auditorNotificationsControllerProvider.notifier)
                          .markAllRead();
                      final state = ref.read(auditorNotificationsControllerProvider);
                      if (state.hasError && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${state.error}'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.done_all),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref
                ..invalidate(auditorNotificationsProvider)
                ..invalidate(auditorUnreadNotificationsCountProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              title: 'Error',
              message: 'No se pudieron cargar tus notificaciones.\n$e',
              icon: Icons.error_outline,
              onAction: () => ref.invalidate(auditorNotificationsProvider),
              actionLabel: 'Reintentar',
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'Sin notificaciones',
                message: 'Aquí aparecerán avisos sobre alertas y recordatorios.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final notification = list[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () async {
                    if (!notification.leido) {
                      await ref
                          .read(auditorNotificationsControllerProvider.notifier)
                          .markRead(notification.id);
                    }
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (_) => _NotificationDetailDialog(
                        title: notification.titulo ?? 'Notificación',
                        message: notification.mensaje ?? 'Sin mensaje.',
                        createdAt: notification.creadoEn,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationDetailDialog extends StatelessWidget {
  final String title;
  final String message;
  final DateTime? createdAt;

  const _NotificationDetailDialog({
    required this.title,
    required this.message,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final date = createdAt;
    final when = date == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(date);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (when != null) ...[
              Text(
                when,
                style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
            Text(message),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

