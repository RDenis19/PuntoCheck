import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeListItem extends StatelessWidget {
  const EmployeeListItem({
    super.key,
    required this.name,
    required this.role,
    required this.active,
    required this.lastEntry,
    required this.lastDate,
    required this.lastExit,
    required this.onTap,
  });

  final String name;
  final String role;
  final bool active;
  final String lastEntry;
  final String lastExit;
  final String lastDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: Stack(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryRed,
            child: Icon(Icons.person, color: AppColors.white),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: active ? Colors.green : AppColors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.login, size: 16, color: AppColors.successGreen),
              const SizedBox(width: 4),
              Text('Entrada $lastEntry', style: _smallText),
              const SizedBox(width: 12),
              Icon(Icons.logout, size: 16, color: AppColors.primaryRed),
              const SizedBox(width: 4),
              Text('Salida $lastExit', style: _smallText),
            ],
          ),
          const SizedBox(height: 4),
          Text('Asltimo dAa: $lastDate', style: _smallText),
        ],
      ),
    );
  }

  TextStyle get _smallText =>
      TextStyle(color: AppColors.black.withValues(alpha: 0.6), fontSize: 12);
}
