import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final bool isPositive;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusChip({
    super.key,
    required this.label,
    this.isPositive = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (isPositive
            ? AppColors.successGreen.withValues(alpha: 0.12)
            : AppColors.neutral200);
    final fg = textColor ?? (isPositive ? AppColors.successGreen : AppColors.neutral600);

    return Chip(
      backgroundColor: bg,
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
