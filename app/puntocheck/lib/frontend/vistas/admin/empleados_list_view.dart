import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/vistas/admin/widgets/employee_list_item.dart';
import 'package:puntocheck/frontend/vistas/admin/widgets/employee_stats_cards.dart';
import 'package:puntocheck/frontend/widgets/text_field_icon.dart';

class EmpleadosListView extends StatefulWidget {
  const EmpleadosListView({super.key});

  @override
  State<EmpleadosListView> createState() => _EmpleadosListViewState();
}

class _EmpleadosListViewState extends State<EmpleadosListView> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

  final List<Map<String, dynamic>> _employees = [
    {
      'name': 'Pablo Criollo',
      'role': 'Empleado',
      'active': true,
      'entry': '08:45',
      'exit': '17:30',
      'date': '31/10/2025',
    },
    {
      'name': 'Ana Ramirez',
      'role': 'Admin',
      'active': true,
      'entry': '08:10',
      'exit': '17:15',
      'date': '31/10/2025',
    },
    {
      'name': 'Luis Salinas',
      'role': 'Empleado',
      'active': false,
      'entry': '--',
      'exit': '--',
      'date': '29/10/2025',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      const EmployeeStatData(label: 'Total', value: '6'),
      const EmployeeStatData(label: 'Activos', value: '5'),
      const EmployeeStatData(label: 'Prom. asistencia', value: '89.4%'),
    ];

    final filtered = _employees.where((employee) {
      final matchesSearch = (employee['name']! as String)
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      final matchesFilter = switch (_selectedFilter) {
        0 => true,
        1 => employee['active'] == true,
        2 => employee['active'] == false,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmployeeStatsCards(stats: stats),
          const SizedBox(height: 20),
          TextFieldIcon(
            controller: _searchController,
            hintText: 'Buscar por nombre o email…',
            prefixIcon: Icons.search,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 12),
          for (final employee in filtered)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: EmployeeListItem(
                name: employee['name']! as String,
                role: employee['role']! as String,
                active: employee['active']! as bool,
                lastEntry: employee['entry']! as String,
                lastExit: employee['exit']! as String,
                lastDate: employee['date']! as String,
                onTap: () {
                  // TODO(backend): pasar ID del empleado para cargar detalle desde backend.
                  Navigator.pushNamed(
                    context,
                    AppRouter.adminEmpleadoDetalle,
                    arguments: employee,
                  );
                },
              ),
            ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Sin resultados')),
            ),
          // TODO(backend): la búsqueda y filtros deben llamar a endpoints paginados.
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Activos', 'Inactivos'];
    return Row(
      children: List.generate(filters.length, (index) {
        final selected = _selectedFilter == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryRed : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.black.withValues(alpha: 0.1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: selected
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
    );
  }
}
