import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/notice_card.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class AvisosView extends StatelessWidget {
  const AvisosView({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final notices = [
      {
        'titulo': 'Actualiza tu información personal',
        'descripcion': 'Confirma tus datos antes del cierre de mes.',
        'fecha': 'Hoy · 9:15 AM',
        'color': AppColors.primaryRed,
        'detalle':
            'Hola Pablo, necesitamos que confirmes tu información personal para mantener tus datos actualizados. Revisa tu correo y valida tu dirección para evitar inconvenientes.',
        'unread': true,
      },
      {
        'titulo': 'Nuevo horario desde noviembre',
        'descripcion': 'Tu jornada cambiará a partir del lunes.',
        'fecha': 'Ayer · 5:40 PM',
        'color': AppColors.infoBlue,
        'detalle':
            'Desde el próximo lunes tu horario de ingreso será a las 07:30 AM. Recuerda registrar tu asistencia apenas llegues para mantener la puntualidad.',
        'unread': true,
      },
      {
        'titulo': 'Cumpleaños del Mes',
        'descripcion': '¡Celebramos los cumpleaños de noviembre!',
        'fecha': 'Ayer · 2:00 PM',
        'color': AppColors.successGreen,
        'detalle':
            'Este viernes tendremos un pequeño festejo para reconocer a los cumpleañeros de noviembre. ¡No faltes!',
        'unread': false,
      },
      {
        'titulo': 'Cambio de Horario · Mantenimiento',
        'descripcion': 'Importante: Mantenimiento de instalaciones.',
        'fecha': '29 Oct · 4:30 PM',
        'color': AppColors.warningOrange,
        'detalle':
            'El próximo martes tendremos trabajos de mantenimiento en el área principal, por lo que la jornada se adelantará media hora.',
        'unread': false,
      },
    ];

    final unreadCount = notices
        .where((notice) => notice['unread'] == true)
        .length;

    final listView = ListView(
      padding: EdgeInsets.fromLTRB(0, 12, 0, embedded ? 90 : 12),
      children: [
        for (final notice in notices)
          NoticeCard(
            titulo: notice['titulo'] as String,
            descripcionCorta: notice['descripcion'] as String,
            fechaTexto: notice['fecha'] as String,
            color: notice['color'] as Color,
            unread: notice['unread'] as bool,
            onTap: () => _showNoticeDetail(context, notice),
          ),
      ],
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

  void _showNoticeDetail(BuildContext context, Map<String, Object> notice) {
    // TODO(backend): al abrir el modal debe marcarse el aviso como leído y enviar
    // esa confirmación al backend para métricas internas.
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
                      notice['titulo'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.black.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          notice['fecha'] as String,
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notice['detalle'] as String,
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

