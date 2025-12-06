import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_compliance_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_dashboard_view.dart';
import 'package:puntocheck/presentation/auditor/views/auditor_reports_view.dart';
import 'package:puntocheck/presentation/auditor/widgets/auditor_header.dart';
import 'package:puntocheck/presentation/auditor/widgets/auditor_tab_navigation.dart';

class AuditorShellView extends ConsumerStatefulWidget {
  const AuditorShellView({super.key});

  @override
  ConsumerState<AuditorShellView> createState() => _AuditorShellViewState();
}

class _AuditorShellViewState extends ConsumerState<AuditorShellView> {
  int _index = 0;

  Perfiles? get _profile => ref.read(profileProvider).maybeWhen(
        data: (p) => p,
        orElse: () => null,
      );

  @override
  Widget build(BuildContext context) {
    final pages = const [
      AuditorDashboardView(),
      AuditorComplianceView(),
      AuditorReportsView(),
    ];

    return Scaffold(
      body: Column(
        children: [
          AuditorHeader(
            userName: _profile?.nombres ?? '—',
            organizationName: _profile?.organizacionId ?? 'Sin organización',
          ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: AuditorTabNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
