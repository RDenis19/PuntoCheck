import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeTabNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const EmployeeTabNavigation({
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
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fingerprint),
          label: 'Asistencia',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
