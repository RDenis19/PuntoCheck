import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_home_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_organizations_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_plans_billing_view.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_support_view.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_header.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_tab_navigation.dart';

class SuperAdminShellView extends ConsumerStatefulWidget {
  const SuperAdminShellView({super.key});

  @override
  ConsumerState<SuperAdminShellView> createState() =>
      _SuperAdminShellViewState();
}

class _SuperAdminShellViewState extends ConsumerState<SuperAdminShellView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    final pages = const [
      SuperAdminHomeView(),
      SuperAdminOrganizationsView(),
      SuperAdminPlansBillingView(),
      SuperAdminSupportView(),
    ];

    Widget body;
    String userName = 'Super Admin';

    profileAsync.when(
      data: (perfil) {
        if (perfil != null && perfil.nombres.isNotEmpty) {
          userName = perfil.nombres;
        }
      },
      loading: () {},
      error: (_, __) {},
    );

    body = Column(
      children: [
        if (_currentIndex == 0) ...[
          SuperAdminHeader(
            userName: userName,
            roleLabel: 'Super Admin',
            organizationName: null,
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
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(child: body),
      bottomNavigationBar: SuperAdminTabNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
