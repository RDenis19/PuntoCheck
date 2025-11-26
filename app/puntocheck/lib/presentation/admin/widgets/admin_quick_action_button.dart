import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AdminQuickActionButton extends StatelessWidget {
  const AdminQuickActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(20);

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Material(
        color: AppColors.white,
        borderRadius: cardRadius,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.05),
        child: InkWell(
          borderRadius: cardRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primaryRed),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
