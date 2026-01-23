import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_alerts_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_attendance_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_dashboard_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_leaves_hours_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_profile_view.dart';
import 'package:puntocheck/presentation/shared/widgets/home_header.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/providers/auditor_notifications_providers.dart';
import 'package:puntocheck/routes/app_router.dart';

class AuditorShellView extends ConsumerStatefulWidget {
  const AuditorShellView({super.key});

  @override
  ConsumerState<AuditorShellView> createState() => _AuditorShellViewState();
}

class _AuditorShellViewState extends ConsumerState<AuditorShellView> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(auditorProfileProvider);
    final orgAsync = ref.watch(auditorOrganizationProvider);
    final index = ref.watch(auditorTabIndexProvider);
    final unreadAsync = ref.watch(auditorUnreadNotificationsCountProvider);

    final pages = const [
      AuditorDashboardView(),
      AuditorAttendanceView(),
      AuditorLeavesHoursView(),
      AuditorAlertsView(),
      AuditorProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          if (index == 0)
            profileAsync.when(
              loading: () => const HomeHeader(
                userName: 'Cargando...',
                roleName: 'Auditor',
              ),
              error: (_, __) =>
                  const HomeHeader(userName: 'Error', roleName: 'Auditor'),
              data: (profile) {
                final orgName = orgAsync.maybeWhen(
                  data: (org) => org.razonSocial,
                  orElse: () => '',
                );
                return HomeHeader(
                  userName: profile.nombres,
                  organizationName: orgName,
                  roleName: 'Auditor',
                  notificationCount: unreadAsync.valueOrNull ?? 0,
                  onNotificationTap: () =>
                      context.push('${AppRoutes.auditorHome}/notificaciones'),
                );
              },
            ),
          Expanded(child: pages[index.clamp(0, pages.length - 1)]),
        ],
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
              ref.read(auditorTabIndexProvider.notifier).state = i,
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
                Icons.policy_outlined,
                size: 24,
                color: AppColors.neutral600,
              ),
              selectedIcon: Icon(
                Icons.policy,
                size: 26,
                color: AppColors.primaryRed,
              ),
              label: 'Alertas',
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
