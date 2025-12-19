import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_alerts_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_attendance_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_dashboard_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_leaves_hours_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_profile_view.dart';
import 'package:puntocheck/presentation/auditor/widgets/auditor_header.dart';
import 'package:puntocheck/presentation/auditor/widgets/auditor_tab_navigation.dart';
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
      body: Column(
        children: [
          if (index == 0)
            profileAsync.when(
              loading: () => const SafeArea(
                bottom: false,
                child: AuditorHeader(userName: 'Cargando...', organizationName: ''),
              ),
              error: (_, __) => const SafeArea(
                bottom: false,
                child: AuditorHeader(userName: 'Error', organizationName: ''),
              ),
              data: (profile) {
                final orgName = orgAsync.maybeWhen(
                  data: (org) => org.razonSocial,
                  orElse: () => 'Cargando...',
                );
                return SafeArea(
                  bottom: false,
                  child: AuditorHeader(
                    userName: profile.nombres,
                    organizationName: orgName,
                    unreadNotificationsCount: unreadAsync.valueOrNull,
                    onNotificationsPressed: () => context.push(
                      '${AppRoutes.auditorHome}/notificaciones',
                    ),
                  ),
                );
              },
            ),
          Expanded(child: pages[index.clamp(0, pages.length - 1)]),
        ],
      ),
      bottomNavigationBar: AuditorTabNavigation(
        currentIndex: index,
        onTap: (i) => ref.read(auditorTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
