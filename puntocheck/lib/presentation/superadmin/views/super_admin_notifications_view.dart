import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/notificacion.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminNotificationsView extends ConsumerWidget {
  const SuperAdminNotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(superAdminNotificationsProvider);

    Future<void> onRefresh() async {
      ref.invalidate(superAdminNotificationsProvider);
      await ref.read(superAdminNotificationsProvider.future);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: notificationsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final n = list[index];
                return _NotificationCard(notification: n);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.neutral600),
                const SizedBox(height: 12),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.neutral700),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final Notificacion notification;

  @override
  Widget build(BuildContext context) {
    final color = notification.leido ? AppColors.neutral400 : AppColors.primaryRed;
    final created = notification.creadoEn != null
        ? notification.creadoEn!.toLocal().toString().split(' ').first
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.notifications, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.titulo ?? 'Notificación',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                    if (notification.tipo != null && notification.tipo!.isNotEmpty)
                      _Pill(label: notification.tipo!, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                if ((notification.mensaje ?? '').isNotEmpty)
                  Text(
                    notification.mensaje!,
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.business_outlined,
                      label: notification.organizacionId,
                    ),
                    if (created.isNotEmpty)
                      _MetaChip(
                        icon: Icons.schedule,
                        label: created,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral700),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.neutral500),
            SizedBox(height: 10),
            Text(
              'Sin notificaciones',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Aquí verás los avisos globales del sistema.',
              style: TextStyle(color: AppColors.neutral600),
            ),
          ],
        ),
      ),
    );
  }
}
