import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/manager/views/manager_approvals_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_dashboard_view.dart';
import 'package:puntocheck/presentation/manager/views/manager_shifts_view.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_header.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_tab_navigation.dart';

class ManagerShellView extends ConsumerStatefulWidget {
  const ManagerShellView({super.key});

  @override
  ConsumerState<ManagerShellView> createState() => _ManagerShellViewState();
}

class _ManagerShellViewState extends ConsumerState<ManagerShellView> {
  int _index = 0;

  Perfiles? get _profile => ref.read(profileProvider).maybeWhen(
        data: (p) => p,
        orElse: () => null,
      );

  @override
  Widget build(BuildContext context) {
    final pages = const [
      ManagerDashboardView(),
      ManagerApprovalsView(),
      ManagerShiftsView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          ManagerHeader(
            userName: _profile?.nombres ?? '—',
            organizationName: _profile?.organizacionId ?? 'Sin organización',
          ),
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
