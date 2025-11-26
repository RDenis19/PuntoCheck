import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/notification_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/notice_card.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class AvisosView extends ConsumerWidget {
  const AvisosView({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final listView = noticesAsync.when(
      data: (notices) {
        if (notices.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(0, 24, 0, embedded ? 90 : 24),
            child: _EmptyNotices(embedded: embedded),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(0, 12, 0, embedded ? 90 : 12),
          children: [
            for (final notice in notices)
              NoticeCard(
                titulo: notice.title,
                descripcionCorta: notice.body,
                fechaTexto: _formatDate(notice.createdAt),
                color: _colorForType(notice.type),
                unread: !notice.isRead,
                onTap: () => _showNoticeDetail(context, ref, notice),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar avisos')),
    );

    if (embedded) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EmbeddedHeader(unreadCount: unreadCount),
            Expanded(child: listView),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Avisos',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [_UnreadBadge(unreadCount: unreadCount)],
      ),
      body: listView,
    );
  }

  Future<void> _showNoticeDetail(
    BuildContext context,
    WidgetRef ref,
    AppNotification notice,
  ) async {
    await ref.read(notificationControllerProvider.notifier).markAsRead(notice.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                    Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(notice.createdAt),
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notice.body,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.black.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} - $hour:$minute';
  }

  static Color _colorForType(NotifType type) {
    switch (type) {
      case NotifType.alerta:
        return AppColors.primaryRed;
      case NotifType.sistema:
        return AppColors.infoBlue;
      case NotifType.info:
      default:
        return AppColors.successGreen;
    }
  }
}

class _EmbeddedHeader extends StatelessWidget {
  const _EmbeddedHeader({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Avisos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.backgroundDark,
            ),
          ),
          _UnreadBadge(unreadCount: unreadCount),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, size: 16, color: AppColors.primaryRed),
          const SizedBox(width: 6),
          Text(
            '$unreadCount',
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotices extends StatelessWidget {
  const _EmptyNotices({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_none,
          size: 64,
          color: AppColors.backgroundDark.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'No tienes avisos',
          style: TextStyle(
            color: AppColors.backgroundDark.withValues(alpha: 0.7),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Te notificaremos cuando llegue uno nuevo',
          style: TextStyle(
            color: AppColors.backgroundDark.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        if (!embedded) const SizedBox(height: 32),
      ],
    );
  }
}
