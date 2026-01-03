import 'package:flutter/material.dart';
import 'package:puntocheck/models/notificacion.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Card para mostrar una notificación
class NotificationCard extends StatelessWidget {
  final Notificacion notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  IconData get _icon {
    switch (notification.tipo) {
      case 'alerta':
        return Icons.warning_amber;
      case 'aprobacion':
        return Icons.check_circle_outlined;
      case 'rechazo':
        return Icons.cancel_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.tipo) {
      case 'alerta':
        return AppColors.warningOrange;
      case 'aprobacion':
        return AppColors.successGreen;
      case 'rechazo':
        return AppColors.errorRed;
      case 'info':
        return AppColors.infoBlue;
      default:
        return AppColors.neutral600;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.leido
              ? AppColors.neutral200
              : _iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titulo ?? 'Notificación',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.leido
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.leido)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.mensaje != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.mensaje!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral700,
                          fontWeight: notification.leido
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notification.creadoEn),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
