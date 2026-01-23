import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/employee/views/employee_home_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_attendance_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_requests_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_profile_view.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeShellView extends ConsumerStatefulWidget {
  const EmployeeShellView({super.key});

  @override
  ConsumerState<EmployeeShellView> createState() => _EmployeeShellViewState();
}

class _EmployeeShellViewState extends ConsumerState<EmployeeShellView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EmployeeHomeView(),
    EmployeeAttendanceView(),
    EmployeeRequestsView(),
    EmployeeProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Mantiene providers del employee actualizados en tiempo real (si Realtime está habilitado).
    ref.watch(employeeRealtimeListenerProvider);

    return Scaffold(
      body: _pages[_currentIndex],
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
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppColors.primaryRed.withValues(alpha: 0.12),
          shadowColor: Colors.black.withValues(alpha: 0.1),
          elevation: 3.0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.home_filled,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Inicio',
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
                Icons.event_note_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.event_note,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Permisos',
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
