import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_person_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_person_detail_view.dart';
import 'package:puntocheck/presentation/admin/widgets/async_error_view.dart';
import 'package:puntocheck/presentation/admin/widgets/branch_selector.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
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

  // Roles definidos
  final _roles = <MapEntry<String, RolUsuario?>>[
    const MapEntry('Todas', null),
    const MapEntry('Admin', RolUsuario.orgAdmin),
    const MapEntry('Manager', RolUsuario.manager),
    const MapEntry('Auditor', RolUsuario.auditor),
    const MapEntry('Empleado', RolUsuario.employee),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha del provider filtro
    final filter = OrgAdminPeopleFilter(
      search: _search,
      role: _role,
      active: _active,
      branchId: _branchId,
    );
    final staffAsync = ref.watch(orgAdminStaffProvider(filter));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. SliverAppBar con título y barra de búsqueda
          SliverAppBar(
            floating: true,
            pinned: true,

            /// Mantener visible al hacer scroll hacia arriba
            snap: false,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            expandedHeight: kToolbarHeight + 60,

            /// Altura para Título + Buscador
            title: const Text(
              'Colaboradores',
              style: TextStyle(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w800,
                fontSize: 20, // Ajustado para evitar overflow
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: false,
            // Usamos 'bottom' para la barra de búsqueda para que sea parte del AppBar
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                alignment: Alignment.center,
                child: SizedBox(
                  height: 48, // Altura cómoda para touch
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar empleado...',
                      hintStyle: TextStyle(
                        color: AppColors.neutral700.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.neutral700.withValues(alpha: 0.5),
                      ),
                      contentPadding:
                          EdgeInsets.zero, // Centra el texto vertical
                      filled: true,
                      fillColor: AppColors.secondaryWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primaryRed,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => setState(
                      () => _search = value.trim().isEmpty ? null : value,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Filtros persistentes (Sticky)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFiltersDelegate(
              minHeight: 60,
              maxHeight: 60,
              child: Container(
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    // Filtro de Roles
                    ..._roles.map((entry) {
                      final selected = _role == entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: entry.key,
                          selected: selected,
                          onSelected: () {
                            setState(() => _role = entry.value);
                          },
                        ),
                      );
                    }),
                    // Separador vertical
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 1,
                      height: 24,
                      color: AppColors.neutral200,
                    ),
                    // Filtro de Estado
                    _FilterChip(
                      label: 'Todos',
                      selected: _active == null,
                      onSelected: () => setState(() => _active = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Activos',
                      selected: _active == true,
                      onSelected: () => setState(() => _active = true),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactivos',
                      selected: _active == false,
                      onSelected: () => setState(() => _active = false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Selector de Sucursal (No sticky, pero parte del flujo)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: BranchSelector(
                label: 'Filtrar por Sucursal',
                selectedBranchId: _branchId,
                onChanged: (value) => setState(() => _branchId = value),
              ),
            ),
          ),

          // 4. Lista de Resultados
          staffAsync.when(
            data: (staff) {
              if (staff.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: EmptyState(
                      icon: Icons.groups_rounded,
                      title: 'No se encontraron colaboradores',
                      subtitle: 'Intenta ajustar los filtros de búsqueda.',
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final perfil = staff[index];
                    // Reimplementación local de OrgAdminPersonItem mejorada
                    return _PersonListItem(
                      perfil: perfil,
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                OrgAdminPersonDetailView(userId: perfil.id),
                          ),
                        );
                        if (mounted && updated == true) {
                          ref.invalidate(orgAdminStaffProvider(filter));
                        }
                      },
                    );
                  }, childCount: staff.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AsyncErrorView(
                  error: e,
                  onRetry: () => ref.refresh(orgAdminStaffProvider(filter)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-people',
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_rounded),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const OrgAdminNewPersonView()),
          );
          if (mounted && created == true) {
            ref.invalidate(orgAdminStaffProvider(filter));
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Componentes Locales
// -----------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryRed : AppColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryRed : AppColors.neutral700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PersonListItem extends StatelessWidget {
  final Perfiles perfil;
  final VoidCallback onTap;

  const _PersonListItem({required this.perfil, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${perfil.nombres.isNotEmpty ? perfil.nombres[0] : ''}${perfil.apellidos.isNotEmpty ? perfil.apellidos[0] : ''}'
            .toUpperCase();
    final isActive = perfil.activo != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.neutral200.withValues(alpha: 0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con Indicador de Estado
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryRed.withValues(
                        alpha: 0.08,
                      ),
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.successGreen
                              : AppColors.neutral400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${perfil.nombres} ${perfil.apellidos}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        perfil.rol?.value ?? 'Sin rol',
                        style: const TextStyle(
                          color: AppColors.neutral600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Acciones Rápidas
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.neutral400,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onTap();
                    // Aquí se podrían agregar más acciones futuras como "Llamar"
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ver Detalle'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFiltersDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyFiltersDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
