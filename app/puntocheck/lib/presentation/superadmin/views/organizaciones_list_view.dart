import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card_with_stats.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_section_title.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrganizacionesListView extends ConsumerStatefulWidget {
  const OrganizacionesListView({super.key});

  @override
  ConsumerState<OrganizacionesListView> createState() =>
      _OrganizacionesListViewState();
}

class _OrganizacionesListViewState
    extends ConsumerState<OrganizacionesListView> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;
  int _sortOption = 0; // 0: reciente, 1: A-Z

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(allOrganizationsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Organizaciones'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: orgsAsync.when(
        data: (orgs) => _buildBody(context, orgs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Error cargando organizaciones')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Organization> orgs) {
    final filtered = orgs.where(_matchesQueryAndFilter).toList()
      ..sort((a, b) {
        if (_sortOption == 1) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SaSectionTitle(title: 'Buscar'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFieldIcon(
            controller: _searchController,
            hintText: 'Buscar por nombre o correo...',
            prefixIcon: Icons.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        _buildFilters(orgs),
        const SizedBox(height: 12),
        _buildSorter(),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 56,
                    color: AppColors.black.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No se encontraron organizaciones',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  Text(
                    'Ajusta la busqueda o los filtros.',
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map(
            (org) => SaOrganizationCardWithStats(
              organization: org,
              onTap: () => context.push(
                AppRoutes.superAdminOrganizacionDetalle,
                extra: org,
              ),
            ),
          ),
      ],
    );
  }

  bool _matchesQueryAndFilter(Organization org) {
    final query = _searchController.text.toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        org.name.toLowerCase().contains(query) ||
        (org.contactEmail?.toLowerCase().contains(query) ?? false);

    final filterStatus = switch (_selectedFilter) {
      1 => OrgStatus.activa,
      2 => OrgStatus.suspendida,
      3 => OrgStatus.prueba,
      _ => null,
    };

    final matchesFilter = filterStatus == null || org.status == filterStatus;
    return matchesSearch && matchesFilter;
  }

  Widget _buildSorter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Ordenar por:',
            style: TextStyle(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _sortOption,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Mas recientes')),
              DropdownMenuItem(value: 1, child: Text('Nombre A-Z')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sortOption = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<Organization> orgs) {
    const filters = ['Todos', 'Activas', 'Suspendidas', 'Prueba'];
    final counts = _statusCounts(orgs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilter == index;
          final chipCount = switch (index) {
            1 => counts[OrgStatus.activa] ?? 0,
            2 => counts[OrgStatus.suspendida] ?? 0,
            3 => counts[OrgStatus.prueba] ?? 0,
            _ => orgs.length,
          };

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        filters[index],
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.black.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chipCount.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.black.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Map<OrgStatus, int> _statusCounts(List<Organization> orgs) {
    final counts = <OrgStatus, int>{
      OrgStatus.activa: 0,
      OrgStatus.suspendida: 0,
      OrgStatus.prueba: 0,
    };
    for (final org in orgs) {
      counts[org.status] = (counts[org.status] ?? 0) + 1;
    }
    return counts;
  }
}
