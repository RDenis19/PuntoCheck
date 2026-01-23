import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/manager/views/manager_attendance_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_dashboard_view.dart';

import 'package:puntocheck/presentation/manager/views/manager_profile_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_shifts_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_team_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Shell principal del Manager con navegación persistente (IndexedStack).
/// Cada vista maneja su propio AppBar/Header.
class ManagerShellView extends ConsumerStatefulWidget {
  const ManagerShellView({super.key});

  @override
  ConsumerState<ManagerShellView> createState() => _ManagerShellViewState();
}

class _ManagerShellViewState extends ConsumerState<ManagerShellView> {
  int _index = 0;

  final _pages = const [
    ManagerDashboardView(), // 0: Inicio
    ManagerTeamView(), // 1: Mi Equipo
    ManagerAttendanceView(), // 2: Asistencia
    ManagerShiftsView(), // 3: Horarios
    ManagerProfileView(), // 4: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
                fontSize: 12,
              );
            }
            return const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral600,
              fontSize: 12,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppColors.primaryRed.withValues(alpha: 0.12),
          shadowColor: Colors.black.withValues(alpha: 0.1),
          elevation: 3.0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.dashboard,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.people_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.people,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Equipo',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.access_time_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.access_time_filled,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Asistencia',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.calendar_month,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Horarios',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.person,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
