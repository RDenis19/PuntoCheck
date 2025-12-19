import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeNotificationsView extends ConsumerWidget {
  const EmployeeNotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(employeeNotificationsProvider);
    final controllerAsync = ref.watch(employeeNotificationControllerProvider);

    final unread = notificationsAsync.valueOrNull
            ?.where((n) => n['leido'] != true)
            .length ??
        0;

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
                          .read(employeeNotificationControllerProvider.notifier)
                          .markAllRead();
                      final state = ref.read(employeeNotificationControllerProvider);
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(employeeNotificationsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'Sin notificaciones',
                message: 'Aquí aparecerán tus avisos y aprobaciones.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = list[index];
                return _NotificationTile(notification: n);
              },
            );
          },
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
    final id = (notification['id'] ?? '').toString();
    final isRead = notification['leido'] == true;
    final type = notification['tipo'] ?? 'info';
    final created = DateTime.tryParse(notification['creado_en'] ?? '') ?? DateTime.now();

    IconData icon;
    Color color;
    switch (type) {
      case 'permiso':
        icon = Icons.assignment_turned_in_outlined;
        color = AppColors.primaryRed;
        break;
      case 'asistencia':
        icon = Icons.access_time;
        color = AppColors.infoBlue;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.neutral600;
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.neutral200,
        child: const Icon(Icons.check, color: AppColors.neutral700),
      ),
      confirmDismiss: (_) async {
        await ref.read(employeeNotificationControllerProvider.notifier).markRead(id);
        return false; // no remover el item visualmente
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primaryRed.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppColors.neutral200
                : AppColors.primaryRed.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (!isRead) {
              await ref
                  .read(employeeNotificationControllerProvider.notifier)
                  .markRead(id);
            }
            if (!context.mounted) return;
            _openNotificationDetail(context, notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['titulo'] ?? 'Notificación',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['mensaje'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(created),
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right, color: AppColors.neutral400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return DateFormat('dd/MM').format(date);
  }
}

void _openNotificationDetail(BuildContext context, Map<String, dynamic> n) {
  final title = (n['titulo'] ?? 'Notificación').toString();
  final msg = (n['mensaje'] ?? '').toString();
  final created = DateTime.tryParse(n['creado_en']?.toString() ?? '');
  final fmt = DateFormat('dd/MM/yyyy HH:mm');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Detalle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                if (created != null)
                  Text(
                    fmt.format(created),
                    style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                  ),
                const SizedBox(height: 12),
                Text(
                  msg.isEmpty ? '—' : msg,
                  style: const TextStyle(color: AppColors.neutral700),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
