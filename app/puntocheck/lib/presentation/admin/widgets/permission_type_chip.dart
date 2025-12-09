import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Chip para mostrar el tipo de permiso
class PermissionTypeChip extends StatelessWidget {
  final TipoPermiso tipo;
  final bool compact;

  const PermissionTypeChip({
    super.key,
    required this.tipo,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config.emoji,
            style: TextStyle(fontSize: compact ? 12 : 14),
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

  _TypeConfig _getTypeConfig() {
    if (tipo == TipoPermiso.vacaciones) {
      return _TypeConfig(
        label: 'Vacaciones',
        emoji: '🌴',
        color: AppColors.infoBlue,
      );
    } else if (tipo == TipoPermiso.enfermedad) {
      return _TypeConfig(
        label: 'Enfermedad',
        emoji: '🏥',
        color: AppColors.errorRed,
      );
    } else if (tipo == TipoPermiso.maternidadPaternidad) {
      return _TypeConfig(
        label: 'Maternidad/Paternidad',
        emoji: '👶',
        color: const Color(0xFFEC407A), // Rosa
      );
    } else if (tipo == TipoPermiso.calamidadDomestica) {
      return _TypeConfig(
        label: 'Calamidad',
        emoji: '🏠',
        color: AppColors.warningOrange,
      );
    } else if (tipo == TipoPermiso.legalVotacion) {
      return _TypeConfig(
        label: 'Legal/Votación',
        emoji: '🗳️',
        color: const Color(0xFF42A5F5), // Azul claro
      );
    } else { // otro
      return _TypeConfig(
        label: 'Otro',
        emoji: '📋',
        color: AppColors.neutral600,
      );
    }
  }
}

class _TypeConfig {
  final String label;
  final String emoji;
  final Color color;

  _TypeConfig({
    required this.label,
    required this.emoji,
    required this.color,
  });
}
