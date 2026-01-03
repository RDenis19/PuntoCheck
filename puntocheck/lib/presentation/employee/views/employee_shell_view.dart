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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.neutral500,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              activeIcon: Icon(Icons.access_time_filled_rounded),
              label: 'Asistencia',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_rounded),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'Permisos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
