import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_attendance_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_home_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_leaves_hours_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_profile_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_people_view.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_tab_navigation.dart';
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
      bottomNavigationBar: OrgAdminTabNavigation(
        currentIndex: index,
        onTap: (i) => ref.read(orgAdminTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
