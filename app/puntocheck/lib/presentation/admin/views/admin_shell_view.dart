import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/admin/views/admin_dashboard_view.dart';
import 'package:puntocheck/presentation/admin/views/admin_settings_view.dart';
import 'package:puntocheck/presentation/admin/views/admin_team_view.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_header.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_tab_navigation.dart';

class AdminShellView extends ConsumerStatefulWidget {
  const AdminShellView({super.key});

  @override
  ConsumerState<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends ConsumerState<AdminShellView> {
  int _index = 0;

  Perfiles? get _profile => ref.read(profileProvider).maybeWhen(
        data: (p) => p,
        orElse: () => null,
      );

  @override
  Widget build(BuildContext context) {
    final pages = const [
      AdminDashboardView(),
      AdminTeamView(),
      AdminSettingsView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          AdminHeader(
            userName: _profile?.nombres ?? '—',
            roleLabel: 'Admin de organización',
            organizationName: _profile?.organizacionId ?? 'Sin organización',
          ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: AdminTabNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
