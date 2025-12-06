import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AdminTabNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminTabNavigation({
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
          icon: Icon(Icons.groups_outlined),
          label: 'Equipo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Config',
        ),
      ],
    );
  }
}
