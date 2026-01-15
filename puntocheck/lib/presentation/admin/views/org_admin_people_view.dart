import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_person_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_person_detail_view.dart';
import 'package:puntocheck/presentation/admin/widgets/async_error_view.dart';
import 'package:puntocheck/presentation/admin/widgets/branch_selector.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_person_item.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminPeopleView extends ConsumerStatefulWidget {
  const OrgAdminPeopleView({super.key});

  @override
  ConsumerState<OrgAdminPeopleView> createState() => _OrgAdminPeopleViewState();
}

class _OrgAdminPeopleViewState extends ConsumerState<OrgAdminPeopleView> {
  String? _search;
  RolUsuario? _role;
  bool? _active = true; // null = todos, true = activos, false = inactivos
  String? _branchId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = OrgAdminPeopleFilter(
      search: _search,
      role: _role,
      active: _active,
      branchId: _branchId,
    );
    final staffAsync = ref.watch(orgAdminStaffProvider(filter));

    final roles = <MapEntry<String, RolUsuario?>>[
      const MapEntry('Todas', null),
      const MapEntry('Admin', RolUsuario.orgAdmin),
      const MapEntry('Manager', RolUsuario.manager),
      const MapEntry('Auditor', RolUsuario.auditor),
      const MapEntry('Empleado', RolUsuario.employee),
    ];

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de empleados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o apellido',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setState(
                      () => _search = value.trim().isEmpty ? null : value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: roles.map((entry) {
                        final selected = _role == entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.key),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _role = entry.value),
                            selectedColor: AppColors.primaryRed.withValues(
                              alpha: 0.12,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.primaryRed
                                  : AppColors.neutral700,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Chips de filtro por estado
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatusChip(
                          label: 'Todos',
                          selected: _active == null,
                          onSelected: () => setState(() => _active = null),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'Activos',
                          selected: _active == true,
                          onSelected: () => setState(() => _active = true),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'Inactivos',
                          selected: _active == false,
                          onSelected: () => setState(() => _active = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BranchSelector(
                    label: 'Sucursal',
                    selectedBranchId: _branchId,
                    onChanged: (value) => setState(() => _branchId = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: staffAsync.when(
                data: (staff) {
                  if (staff.isEmpty) {
                    return const EmptyState(
                      icon: Icons.groups_rounded,
                      title: 'No hay personas en la organizacion',
                      subtitle: 'Agrega colaboradores, managers o auditores.',
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final perfil = staff[index];
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.neutral200),
                        ),
                        child: OrgAdminPersonItem(
                          perfil: perfil,
                          onTap: () async {
                            final updated = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => OrgAdminPersonDetailView(
                                      userId: perfil.id,
                                    ),
                                  ),
                                );
                            if (mounted && updated == true) {
                              ref.invalidate(orgAdminStaffProvider(filter));
                            }
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.refresh(orgAdminStaffProvider(filter)),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'fab-people',
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_add_rounded),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const OrgAdminNewPersonView(),
                ),
              );
              if (mounted && created == true) {
                ref.invalidate(orgAdminStaffProvider(filter));
                _scrollToTopAfterCreate();
              }
            },
          ),
        ),
      ],
    );
  }

  void _scrollToTopAfterCreate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ============================================================================
// Widget de chip para filtro de estado
// ============================================================================
class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryRed : AppColors.neutral700,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
