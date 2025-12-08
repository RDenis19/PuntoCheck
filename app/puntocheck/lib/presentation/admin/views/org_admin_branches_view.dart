import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_detail_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branches_map_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_branch_view.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_branch_item.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/async_error_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/providers/app_providers.dart';

class OrgAdminBranchesView extends ConsumerWidget {
  const OrgAdminBranchesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesFuture = ref.watch(_branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: branchesFuture.when(
          data: (branches) {
            if (branches.isEmpty) {
              return EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'Aun no tienes sucursales',
                subtitle: 'Crea tu primera sucursal para definir geocercas y QR.',
                primaryLabel: 'Crear sucursal',
                onPrimary: () => _openCreate(context, ref),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_branchesProvider);
                await ref.read(_branchesProvider.future);
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
                        ref.invalidate(_branchesProvider);
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
            onRetry: () => ref.invalidate(_branchesProvider),
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
      ref.invalidate(_branchesProvider);
    }
  }

  void _openMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrgAdminBranchesMapView()),
    );
  }
}

final _branchesProvider = FutureProvider<List<Sucursales>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null || orgId.isEmpty) {
    throw Exception('No se pudo resolver la organizacion del admin.');
  }
  return ref.read(organizationServiceProvider).getBranches(orgId);
});

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




