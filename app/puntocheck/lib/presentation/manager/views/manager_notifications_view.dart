import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerNotificationsView extends ConsumerWidget {
  const ManagerNotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(managerNotificationsProvider);
    final unreadCountAsync = ref.watch(managerUnreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leídas',
            icon: Badge(
              isLabelVisible: (unreadCountAsync.valueOrNull ?? 0) > 0,
              label: Text('${unreadCountAsync.valueOrNull ?? 0}'),
              child: const Icon(Icons.done_all),
            ),
            onPressed: () async {
              try {
                await ref
                    .read(managerNotificationControllerProvider.notifier)
                    .markAllRead();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificaciones marcadas como leídas')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerNotificationsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryRed,
          onRefresh: () async => ref.invalidate(managerNotificationsProvider),
          child: notificationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.errorRed),
                const SizedBox(height: 12),
                const Text(
                  'Error cargando notificaciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.neutral600),
                ),
              ],
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'Sin notificaciones',
                  message: 'No tienes nuevas alertas o mensajes.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(notification: notification);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['leido'] == true;
    final type = (notification['tipo'] ?? 'info').toString();
    final createdAtRaw = notification['creado_en']?.toString();
    final date = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

    final (icon, color) = _iconForType(type);

    return Dismissible(
      key: Key(notification['id']?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.neutral200,
        child: const Icon(Icons.check, color: AppColors.neutral700),
      ),
      onDismissed: (_) {
        final id = notification['id']?.toString();
        if (id == null) return;
        ref.read(managerNotificationControllerProvider.notifier).markRead(id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primaryRed.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppColors.neutral200
                : AppColors.primaryRed.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (notification['titulo'] ?? 'Sin título').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (notification['mensaje'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral700,
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                        ),
                        onPressed: () {
                          final id = notification['id']?.toString();
                          if (id == null) return;
                          ref
                              .read(managerNotificationControllerProvider.notifier)
                              .markRead(id);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Marcar leída'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'permiso':
        return (Icons.assignment_turned_in_outlined, AppColors.primaryRed);
      case 'alerta_asistencia':
        return (Icons.warning_amber_rounded, AppColors.warningOrange);
      default:
        return (Icons.info_outline, AppColors.infoBlue);
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return DateFormat('dd/MM').format(date);
  }
}

