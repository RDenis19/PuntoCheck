import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Badge visual para indicar si la marcación fue dentro o fuera de la geocerca
class GeofenceBadge extends StatelessWidget {
  final bool? isInside;
  final double? precisionMeters;
  final bool compact;

  const GeofenceBadge({
    super.key,
    required this.isInside,
    this.precisionMeters,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final inside = isInside ?? true;
    final color = inside ? AppColors.successGreen : AppColors.warningOrange;
    final icon = inside ? Icons.check_circle : Icons.warning_amber_rounded;
    final text = inside ? 'Dentro' : 'Fuera';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                inside ? 'Dentro de geocerca' : 'Fuera de geocerca',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (precisionMeters != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Precisión: ${precisionMeters!.toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
