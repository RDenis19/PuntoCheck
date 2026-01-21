import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/manager/views/manager_attendance_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_dashboard_view.dart';

import 'package:puntocheck/presentation/manager/views/manager_profile_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_shifts_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_team_view.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_tab_navigation.dart';

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
      bottomNavigationBar: ManagerTabNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
