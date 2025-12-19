import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AttendanceTypeStyle {
  final IconData icon;
  final Color color;
  final String label;

  const AttendanceTypeStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}

AttendanceTypeStyle attendanceTypeStyle(String rawType) {
  final type = rawType.trim();
  switch (type) {
    case 'entrada':
      return const AttendanceTypeStyle(
        icon: Icons.login,
        color: AppColors.successGreen,
        label: 'Entrada',
      );
    case 'salida':
      return const AttendanceTypeStyle(
        icon: Icons.logout,
        color: AppColors.primaryRed,
        label: 'Salida',
      );
    case 'inicio_break':
      return const AttendanceTypeStyle(
        icon: Icons.free_breakfast_outlined,
        color: AppColors.warningOrange,
        label: 'Inicio break',
      );
    case 'fin_break':
      return const AttendanceTypeStyle(
        icon: Icons.free_breakfast,
        color: AppColors.warningOrange,
        label: 'Fin break',
      );
    default:
      return const AttendanceTypeStyle(
        icon: Icons.help_outline,
        color: AppColors.neutral500,
        label: 'Marcación',
      );
  }
}

