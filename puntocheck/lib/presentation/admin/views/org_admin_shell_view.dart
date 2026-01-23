import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_attendance_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_home_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_leaves_hours_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_profile_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_people_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/providers/app_providers.dart';

class OrgAdminShellView extends ConsumerStatefulWidget {
  const OrgAdminShellView({super.key});

  @override
  ConsumerState<OrgAdminShellView> createState() => _OrgAdminShellViewState();
}

class _OrgAdminShellViewState extends ConsumerState<OrgAdminShellView> {
  @override
  Widget build(BuildContext context) {
    final index = ref.watch(orgAdminTabIndexProvider);

    final pages = const [
      OrgAdminHomeView(),
      OrgAdminPeopleView(),
      OrgAdminAttendanceView(),
      OrgAdminLeavesAndHoursView(),
      OrgAdminProfileView(),
    ];

    return Scaffold(
      // Usamos IndexedStack para mantener el estado de cada pestaña
      body: IndexedStack(
        index: index.clamp(0, pages.length - 1),
        children: pages,
      ),
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
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(orgAdminTabIndexProvider.notifier).state = i,
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
                Icons.groups_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.groups,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Personas',
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
