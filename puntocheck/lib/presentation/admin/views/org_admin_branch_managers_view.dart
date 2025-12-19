import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminBranchManagersView extends ConsumerStatefulWidget {
  const OrgAdminBranchManagersView({super.key});

  @override
  ConsumerState<OrgAdminBranchManagersView> createState() =>
      _OrgAdminBranchManagersViewState();
}

class _MatrixData {
  const _MatrixData({
    required this.branches,
    required this.managers,
    required this.managerIdsByBranch,
  });

  final List<Sucursales> branches;
  final List<Perfiles> managers;
  final Map<String, Set<String>> managerIdsByBranch;
}

final _matrixProvider = FutureProvider.autoDispose<_MatrixData>((ref) async {
  final branches = await ref.watch(orgAdminBranchesProvider.future);
  final managers = await ref.watch(orgAdminManagersProvider.future);

  final branchIds = branches.map((b) => b.id).toList(growable: false);
  final assignments = await ref
      .read(staffServiceProvider)
      .getBranchManagersForBranches(branchIds);

  final Map<String, Set<String>> byBranch = {
    for (final b in branches) b.id: <String>{},
  };

  for (final a in assignments) {
    byBranch.putIfAbsent(a.sucursalId, () => <String>{}).add(a.managerId);
  }

  return _MatrixData(
    branches: branches,
    managers: managers,
    managerIdsByBranch: byBranch,
  );
});

class _OrgAdminBranchManagersViewState
    extends ConsumerState<OrgAdminBranchManagersView> {
  final Map<String, Set<String>> _initialByBranch = {};
  final Map<String, Set<String>> _draftByBranch = {};
  final Map<String, bool> _savingByBranch = {};

  @override
  Widget build(BuildContext context) {
    final matrixAsync = ref.watch(_matrixProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encargados por sucursal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_matrixProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: matrixAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error cargando datos: $e'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _MatrixData data) {
    if (data.branches.isEmpty) {
      return const Center(child: Text('No hay sucursales.'));
    }
    if (data.managers.isEmpty) {
      return const Center(child: Text('No hay perfiles con rol manager.'));
    }

    _ensureInitialized(data);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: data.branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final branch = data.branches[index];
        final initial = _initialByBranch[branch.id] ?? <String>{};
        final draft = _draftByBranch[branch.id] ?? <String>{};
        final isDirty = !setEquals(initial, draft);
        final isSaving = _savingByBranch[branch.id] == true;

        final subtitle = '${draft.length} seleccionado(s)';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: const Icon(
              Icons.store_mall_directory_outlined,
              color: AppColors.primaryRed,
            ),
            title: Text(
              branch.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.managers.map((m) {
                    final selected = draft.contains(m.id);
                    return FilterChip(
                      selected: selected,
                      showCheckmark: true,
                      label: Text(m.nombreCompleto),
                      onSelected: isSaving
                          ? null
                          : (v) {
                              setState(() {
                                final set = _draftByBranch.putIfAbsent(
                                  branch.id,
                                  () => <String>{},
                                );
                                if (v) {
                                  set.add(m.id);
                                } else {
                                  set.remove(m.id);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving || !isDirty
                          ? null
                          : () {
                              setState(() {
                                _draftByBranch[branch.id] = Set<String>.from(
                                  initial,
                                );
                              });
                            },
                      child: const Text('Revertir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving || !isDirty
                          ? null
                          : () => _save(branchId: branch.id, managerIds: draft),
                      label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureInitialized(_MatrixData data) {
    if (_draftByBranch.isNotEmpty) return;
    for (final branch in data.branches) {
      final ids = data.managerIdsByBranch[branch.id] ?? <String>{};
      _initialByBranch[branch.id] = Set<String>.from(ids);
      _draftByBranch[branch.id] = Set<String>.from(ids);
    }
  }

  Future<void> _save({
    required String branchId,
    required Set<String> managerIds,
  }) async {
    setState(() => _savingByBranch[branchId] = true);
    try {
      await ref
          .read(orgAdminBranchMutationControllerProvider.notifier)
          .setManagers(branchId: branchId, managerIds: managerIds);
      final state = ref.read(orgAdminBranchMutationControllerProvider);
      if (state.hasError) throw state.error!;

      setState(() {
        _initialByBranch[branchId] = Set<String>.from(managerIds);
        _draftByBranch[branchId] = Set<String>.from(managerIds);
      });

      if (!mounted) return;
      showAppSnackBar(context, 'Encargados actualizados');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _savingByBranch[branchId] = false);
    }
  }
}
