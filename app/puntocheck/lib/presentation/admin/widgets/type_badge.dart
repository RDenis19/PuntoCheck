import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Badge visual para indicar el tipo de registro de asistencia
class TypeBadge extends StatelessWidget {
  final String? type;
  final bool compact;

  const TypeBadge({
    super.key,
    required this.type,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(type);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 14, color: config.color),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                color: config.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.15),
            config.color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 20),
          const SizedBox(width: 8),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _getConfig(String? type) {
    switch (type?.toLowerCase()) {
      case 'entrada':
        return _TypeConfig(
          label: 'ENTRADA',
          icon: Icons.login_rounded,
          color: const Color(0xFF2E7D32), // Green 800
        );
      case 'salida':
        return _TypeConfig(
          label: 'SALIDA',
          icon: Icons.logout_rounded,
          color: const Color(0xFF1565C0), // Blue 800
        );
      case 'inicio_break':
        return _TypeConfig(
          label: 'INICIO BREAK',
          icon: Icons.coffee_rounded,
          color: const Color(0xFFEF6C00), // Orange 800
        );
      case 'fin_break':
        return _TypeConfig(
          label: 'FIN BREAK',
          icon: Icons.work_rounded,
          color: const Color(0xFF6A1B9A), // Purple 800
        );
      default:
        return _TypeConfig(
          label: type?.toUpperCase() ?? 'MARCA',
          icon: Icons.access_time_rounded,
          color: AppColors.neutral700,
        );
    }
  }
}

class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
