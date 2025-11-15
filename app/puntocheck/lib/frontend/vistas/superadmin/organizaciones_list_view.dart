import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/vistas/superadmin/mock/organizations_mock.dart';
import 'package:puntocheck/frontend/vistas/superadmin/widgets/sa_organization_card.dart';
import 'package:puntocheck/frontend/vistas/superadmin/widgets/sa_section_title.dart';
import 'package:puntocheck/frontend/widgets/text_field_icon.dart';

class OrganizacionesListView extends StatefulWidget {
  const OrganizacionesListView({super.key});

  @override
  State<OrganizacionesListView> createState() => _OrganizacionesListViewState();
}

class _OrganizacionesListViewState extends State<OrganizacionesListView> {
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
    final filtered = mockOrganizations.where((org) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch =
          org.nombre.toLowerCase().contains(query) ||
          org.adminEmail.toLowerCase().contains(query);

      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 1:
          matchesFilter = org.estado == 'activa';
          break;
        case 2:
          matchesFilter = org.estado == 'suspendida';
          break;
        case 3:
          matchesFilter = org.estado == 'prueba';
          break;
        default:
          matchesFilter = true;
      }
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizaciones'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        children: [
          SaSectionTitle(title: 'Buscar'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFieldIcon(
              controller: _searchController,
              hintText: 'Buscar por nombre o correo del admin…',
              prefixIcon: Icons.search,
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
          // TODO(backend): esta vista debe conectarse a la API con paginación y filtros.
        ],
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
