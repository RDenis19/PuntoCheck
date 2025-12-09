import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/presentation/manager/views/manager_dashboard_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_team_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_attendance_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_profile_view.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_header.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_tab_navigation.dart';

/// Shell principal del Manager con navegación entre 4 vistas:
/// 0. Dashboard (Inicio) - con FAB para acceder a otras funciones
/// 1. Mi Equipo
/// 2. Asistencia
/// 3. Perfil
class ManagerShellView extends ConsumerStatefulWidget {
  const ManagerShellView({super.key});

  @override
  ConsumerState<ManagerShellView> createState() => _ManagerShellViewState();
}

class _ManagerShellViewState extends ConsumerState<ManagerShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(managerProfileProvider);
    final orgAsync = ref.watch(managerOrganizationProvider);

    final pages = const [
      ManagerDashboardView(), // Tab 0: Inicio (con FAB)
      ManagerTeamView(), // Tab 1: Mi Equipo
      ManagerAttendanceView(), // Tab 2: Asistencia
      ManagerProfileView(), // Tab 3: Perfil
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header solo en Dashboard (índice 0)
          if (_index == 0)
            profileAsync.when(
              data: (profile) {
                final userName = profile.nombres;
                final orgName = orgAsync.maybeWhen(
                  data: (org) => org.razonSocial,
                  orElse: () => 'Cargando...',
                );

                return ManagerHeader(
                  userName: userName,
                  organizationName: orgName,
                );
              },
              loading: () => const ManagerHeader(
                userName: 'Cargando...',
                organizationName: '',
              ),
              error: (_, __) => const ManagerHeader(
                userName: 'Error',
                organizationName: '',
              ),
            ),

          // Contenido de la vista actual
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: ManagerTabNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
