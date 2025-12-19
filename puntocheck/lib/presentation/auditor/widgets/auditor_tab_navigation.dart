import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorTabNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuditorTabNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primaryRed,
      unselectedItemColor: AppColors.neutral700,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rule_folder_outlined),
          label: 'Cumplimiento',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.file_download_outlined),
          label: 'Reportes',
        ),
      ],
    );
  }
}
