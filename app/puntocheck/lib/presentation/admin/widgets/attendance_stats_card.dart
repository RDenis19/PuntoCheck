import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card de estadística individual para dashboard de asistencia
class AttendanceStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const AttendanceStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primaryRed,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final ultraDense = h > 0 && h < 92;
        final dense = !ultraDense && h > 0 && h < 105;

        final padding = ultraDense
            ? 8.0
            : dense
            ? 12.0
            : 16.0;
        final iconSize = ultraDense
            ? 18.0
            : dense
            ? 20.0
            : 24.0;
        final iconPadding = ultraDense
            ? 6.0
            : dense
            ? 8.0
            : 10.0;
        final valueFontSize = ultraDense
            ? 18.0
            : dense
            ? 22.0
            : 28.0;
        final gap = ultraDense
            ? 6.0
            : dense
            ? 8.0
            : 12.0;
        final labelFontSize = ultraDense
            ? 11.0
            : dense
            ? 12.0
            : 13.0;
        final subtitleFontSize = ultraDense
            ? 10.0
            : dense
            ? 10.0
            : 11.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                  fontSize: labelFontSize,
                ),
              ),
              if (!ultraDense && subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.neutral500,
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
