import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_attendance_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_home_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_leaves_hours_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_profile_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_people_view.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_header.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_tab_navigation.dart';
import 'package:puntocheck/providers/app_providers.dart';

class OrgAdminShellView extends ConsumerStatefulWidget {
  const OrgAdminShellView({super.key});

  @override
  ConsumerState<OrgAdminShellView> createState() => _OrgAdminShellViewState();
}

class _OrgAdminShellViewState extends ConsumerState<OrgAdminShellView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final orgAsync = ref.watch(orgAdminOrganizationProvider);

    var userName = 'Admin';
    profileAsync.whenData((p) {
      if (p != null && p.nombres.isNotEmpty) {
        userName = p.nombres;
      }
    });

    final orgName = orgAsync.maybeWhen(
      data: (org) => org.razonSocial,
      orElse: () => '',
    );

    final pages = const [
      OrgAdminHomeView(),
      OrgAdminPeopleView(),
      OrgAdminAttendanceView(),
      OrgAdminLeavesAndHoursView(),
      OrgAdminProfileView(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex == 0) ...[
              OrgAdminHeader(
                userName: userName,
                organizationName: orgName,
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: OrgAdminTabNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
