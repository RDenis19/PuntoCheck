import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/super_admin_provider.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_section_title.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

class OrganizacionesListView extends ConsumerStatefulWidget {
  const OrganizacionesListView({super.key});

  @override
  ConsumerState<OrganizacionesListView> createState() => _OrganizacionesListViewState();
}

class _OrganizacionesListViewState extends ConsumerState<OrganizacionesListView> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

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
      appBar: AppBar(
        title: const Text('Organizaciones'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: orgsAsync.when(
        data: (orgs) {
          final filtered = orgs.where((org) {
            final query = _searchController.text.toLowerCase();
            final matchesSearch =
                org.name.toLowerCase().contains(query) ||
                (org.contactEmail?.toLowerCase().contains(query) ?? false);

            bool matchesFilter = true;
            switch (_selectedFilter) {
              case 1:
                matchesFilter = org.status == OrgStatus.activa;
                break;
              case 2:
                matchesFilter = org.status == OrgStatus.suspendida;
                break;
              case 3:
                matchesFilter = org.status == OrgStatus.prueba;
                break;
              default:
                matchesFilter = true;
            }
            return matchesSearch && matchesFilter;
          }).toList();

          return ListView(
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
              _buildFilters(),
              const SizedBox(height: 8),
              ...filtered.map(
                (org) => SaOrganizationCard(
                  organization: org,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.superAdminOrganizacionDetalle,
                    arguments: org,
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No se encontraron organizaciones.')),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error cargando organizaciones')),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = ['Todos', 'Activas', 'Suspendidas', 'Prueba'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}





