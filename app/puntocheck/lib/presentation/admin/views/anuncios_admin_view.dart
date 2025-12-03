import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/notification_model.dart';
import 'package:puntocheck/models/enums.dart';
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
                      final config = _typeConfig(anuncio.type);
                      return NoticeCard(
                        titulo: anuncio.title,
                        descripcionCorta:
                            anuncio.body.isNotEmpty ? anuncio.body : 'Sin mensaje',
                        fechaTexto: _formatDate(anuncio.createdAt),
                        color: config.color,
                        icon: config.icon,
                        unread: !anuncio.isRead,
                        onTap: () => _openAnnouncementDetail(context, anuncio, ref),
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

  void _openAnnouncementDetail(
    BuildContext context,
    AppNotification anuncio,
    WidgetRef ref,
  ) {
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
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _typeConfig(anuncio.type)
                                .color
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _typeConfig(anuncio.type).icon,
                            color: _typeConfig(anuncio.type).color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _typeConfig(anuncio.type).label,
                          style: TextStyle(
                            color: _typeConfig(anuncio.type).color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      anuncio.body.isNotEmpty ? anuncio.body : 'Sin mensaje',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openEditSheet(context, anuncio, ref);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryRed,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(context, anuncio, ref);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
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

  void _openEditSheet(
    BuildContext context,
    AppNotification anuncio,
    WidgetRef ref,
  ) {
    final titleController = TextEditingController(text: anuncio.title);
    final bodyController = TextEditingController(text: anuncio.body);
    NotifType selectedType = anuncio.type;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
          child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Editar anuncio',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 60,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 300,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: NotifType.values.map((type) {
                      final selected = selectedType == type;
                      final config = _typeConfig(type);
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(config.icon, size: 18, color: config.color),
                            const SizedBox(width: 6),
                            Text(config.label),
                          ],
                        ),
                        selected: selected,
                        selectedColor: config.color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: selected ? config.color : AppColors.backgroundDark,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(() => selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: saving ? 'Guardando...' : 'Guardar cambios',
                    enabled: !saving,
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          bodyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa título y mensaje'),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      await ref
                          .read(announcementControllerProvider.notifier)
                          .updateAnnouncement(
                            id: anuncio.id,
                            title: titleController.text.trim(),
                            body: bodyController.text.trim(),
                            type: selectedType,
                          );
                      setState(() => saving = false);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppNotification anuncio,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(announcementControllerProvider.notifier)
                  .deleteAnnouncement(id: anuncio.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifConfig {
  const _NotifConfig({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_NotifConfig _typeConfig(NotifType type) {
  switch (type) {
    case NotifType.alerta:
      return const _NotifConfig(
        label: 'Alerta',
        color: AppColors.primaryRed,
        icon: Icons.warning_amber_rounded,
      );
    case NotifType.sistema:
      return const _NotifConfig(
        label: 'Sistema',
        color: AppColors.infoBlue,
        icon: Icons.settings_suggest_outlined,
      );
    case NotifType.info:
    default:
      return const _NotifConfig(
        label: 'Informativo',
        color: AppColors.successGreen,
        icon: Icons.campaign_outlined,
      );
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
