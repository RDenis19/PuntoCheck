import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/employee/views/employee_attendance_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_dashboard_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_profile_view.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_header.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_tab_navigation.dart';

class EmployeeShellView extends ConsumerStatefulWidget {
  const EmployeeShellView({super.key});

  @override
  ConsumerState<EmployeeShellView> createState() => _EmployeeShellViewState();
}

class _EmployeeShellViewState extends ConsumerState<EmployeeShellView> {
  int _index = 0;

  Perfiles? get _profile => ref.read(profileProvider).maybeWhen(
        data: (p) => p,
        orElse: () => null,
      );

  @override
  Widget build(BuildContext context) {
    final pages = const [
      EmployeeDashboardView(),
      EmployeeAttendanceView(),
      EmployeeProfileView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          EmployeeHeader(
            userName: _profile?.nombres ?? '—',
            organizationName: _profile?.organizacionId ?? 'Sin organización',
          ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: EmployeeTabNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
