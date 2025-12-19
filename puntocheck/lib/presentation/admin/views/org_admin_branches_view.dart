import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_detail_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_managers_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branches_map_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_branch_view.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_branch_item.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/async_error_view.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class OrgAdminBranchesView extends ConsumerWidget {
  const OrgAdminBranchesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesFuture = ref.watch(orgAdminBranchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Kiosko',
            icon: const Icon(Icons.qr_code_2_outlined),
            onPressed: () => context.go(AppRoutes.orgAdminKiosk),
          ),
          IconButton(
            tooltip: 'Encargados',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => _openManagers(context),
          ),
        ],
      ),
      body: SafeArea(
        child: branchesFuture.when(
          data: (branches) {
            if (branches.isEmpty) {
              return EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'Aun no tienes sucursales',
                subtitle:
                    'Crea tu primera sucursal para definir geocercas y QR.',
                primaryLabel: 'Crear sucursal',
                onPrimary: () => _openCreate(context, ref),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orgAdminBranchesProvider);
                await ref.read(orgAdminBranchesProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: branches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = branches[index];
                  return OrgAdminBranchItem(
                    branch: b,
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => OrgAdminBranchDetailView(branch: b),
                        ),
                      );
                      if (updated == true) {
                        ref.invalidate(orgAdminBranchesProvider);
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AsyncErrorView(
            error: e,
            onRetry: () => ref.invalidate(orgAdminBranchesProvider),
          ),
        ),
      ),
      floatingActionButton: _FabActions(
        onCreate: () => _openCreate(context, ref),
        onMap: () => _openMap(context),
      ),
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OrgAdminNewBranchView()),
    );
    if (created == true && context.mounted) {
      ref.invalidate(orgAdminBranchesProvider);
    }
  }

  void _openMap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OrgAdminBranchesMapView()));
  }

  void _openManagers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrgAdminBranchManagersView()),
    );
  }
}

class _FabActions extends StatefulWidget {
  final VoidCallback onCreate;
  final VoidCallback onMap;

  const _FabActions({required this.onCreate, required this.onMap});

  @override
  State<_FabActions> createState() => _FabActionsState();
}

class _FabActionsState extends State<_FabActions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 80, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ActionChip(
                  icon: Icons.map_outlined,
                  label: 'Ver mapa',
                  onTap: () {
                    setState(() => _expanded = false);
                    widget.onMap();
                  },
                ),
                const SizedBox(height: 10),
                _ActionChip(
                  icon: Icons.add,
                  label: 'Crear sucursal',
                  onTap: () {
                    setState(() => _expanded = false);
                    widget.onCreate();
                  },
                ),
              ],
            ),
          ),
        FloatingActionButton(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Icon(_expanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
