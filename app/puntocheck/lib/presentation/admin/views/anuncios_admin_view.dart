import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/notification_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/notice_card.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class AnunciosAdminView extends ConsumerWidget {
  const AnunciosAdminView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncios'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: noticesAsync.when(
                data: (notices) {
                  if (notices.isEmpty) {
                    return const _EmptyAnnouncements();
                  }

                  return ListView.builder(
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final anuncio = notices[index];
                      return NoticeCard(
                        titulo: anuncio.title,
                        descripcionCorta: anuncio.body,
                        fechaTexto: _formatDate(anuncio.createdAt),
                        color: AppColors.primaryRed,
                        unread: !anuncio.isRead,
                        onTap: () => _openAnnouncementDetail(context, anuncio),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error cargando anuncios')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PrimaryButton(
                text: 'Nuevo Anuncio',
                onPressed: () => context.push(AppRoutes.adminNuevoAnuncio),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAnnouncementDetail(BuildContext context, AppNotification anuncio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
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
                      anuncio.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDate(anuncio.createdAt),
                      style: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      anuncio.body,
                      style: const TextStyle(fontSize: 15, height: 1.5),
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
}

class _EmptyAnnouncements extends StatelessWidget {
  const _EmptyAnnouncements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 56,
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Aun no hay anuncios',
              style: TextStyle(
                color: AppColors.backgroundDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Publica uno nuevo para tu equipo',
              style: TextStyle(
                color: AppColors.backgroundDark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
