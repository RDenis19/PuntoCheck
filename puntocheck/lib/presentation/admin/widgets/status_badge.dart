import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Badge para mostrar el estado de una solicitud de permiso
class StatusBadge extends StatelessWidget {
  final EstadoAprobacion estado;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.estado,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 14 : 16,
            color: config.color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            config.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig() {
    if (estado == EstadoAprobacion.pendiente) {
      return _StatusConfig(
        label: 'Pendiente',
        color: AppColors.warningOrange,
        icon: Icons.pending_rounded,
      );
    } else if (estado == EstadoAprobacion.aprobadoManager) {
      return _StatusConfig(
        label: 'Aprobado',
        color: AppColors.successGreen,
        icon: Icons.check_circle_outlined,
      );
    } else if (estado == EstadoAprobacion.aprobadoRrhh) {
      return _StatusConfig(
        label: 'Aprobado',
        color: AppColors.successGreen,
        icon: Icons.check_circle_outlined,
      );
    } else if (estado == EstadoAprobacion.rechazado) {
      return _StatusConfig(
        label: 'Rechazado',
        color: AppColors.errorRed,
        icon: Icons.cancel_rounded,
      );
    } else { // cancelado_usuario
      return _StatusConfig(
        label: 'Cancelado',
        color: AppColors.neutral600,
        icon: Icons.block_rounded,
      );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
