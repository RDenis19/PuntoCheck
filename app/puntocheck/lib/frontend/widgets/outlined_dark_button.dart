import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_theme.dart';

/// Botón con borde oscuro para acciones secundarias.
class OutlinedDarkButton extends StatelessWidget {
  const OutlinedDarkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: AppTheme.darkTextColor,
          width: 1.5,
        ),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: AppTheme.darkTextColor,
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.darkTextColor),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.darkTextColor),
                  const SizedBox(width: 8),
                ],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}