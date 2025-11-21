import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/admin/widgets/employee_list_item.dart';
import 'package:puntocheck/presentation/admin/widgets/employee_stats_cards.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/admin_provider.dart';

class EmpleadosListView extends ConsumerStatefulWidget {
  const EmpleadosListView({super.key});

  @override
  ConsumerState<EmpleadosListView> createState() => _EmpleadosListViewState();
}

class _EmpleadosListViewState extends ConsumerState<EmpleadosListView> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

  // final List<Map<String, dynamic>> _employees = []; // Eliminado mock

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(orgEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: employeesAsync.when(
        data: (employees) {
          final filtered = employees.where((employee) {
            final matchesSearch = (employee.fullName ?? '')
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
            // TODO: Implementar filtro de activos/inactivos real si tuviéramos ese campo en Profile o cruzando con Shifts
            return matchesSearch;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EmployeeStatsCards(stats: [
                 EmployeeStatData(label: 'Total', value: '${employees.length}'),
                 const EmployeeStatData(label: 'Activos', value: '--'), // Requiere cruce con shifts
                 const EmployeeStatData(label: 'Promedio', value: '--'),
              ]),
              const SizedBox(height: 20),
              TextFieldIcon(
                controller: _searchController,
                hintText: 'Buscar por nombre...',
                prefixIcon: Icons.search,
                keyboardType: TextInputType.text,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Sin resultados')),
                )
              else
                ...filtered.map((employee) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: EmployeeListItem(
                    name: employee.fullName ?? 'Sin Nombre',
                    role: employee.jobTitle,
                    active: false, // TODO: Real time status
                    lastEntry: '--',
                    lastExit: '--',
                    lastDate: '--',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.adminEmpleadoDetalle,
                        arguments: employee, // Pasamos el objeto Profile real
                      );
                    },
                  ),
                )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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




