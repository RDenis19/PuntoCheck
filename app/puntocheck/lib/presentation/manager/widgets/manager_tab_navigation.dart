import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerTabNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ManagerTabNavigation({
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
          icon: Icon(Icons.mail_outlined),
          label: 'Aprobaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Turnos',
        ),
      ],
    );
  }
}
