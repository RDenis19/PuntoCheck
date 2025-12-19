import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/providers/org_admin_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Selector dropdown de empleado para filtros
class EmployeeSelector extends ConsumerWidget {
  final String? selectedEmployeeId;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool showAllOption;

  const EmployeeSelector({
    super.key,
    this.selectedEmployeeId,
    required this.onChanged,
    this.label,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(
      orgAdminStaffProvider(
        const OrgAdminPeopleFilter(active: true),
      ),
    );

    return employeesAsync.when(
      data: (employees) {
        // Filtrar solo activos
        final activeEmployees = employees.where((e) => e.activo == true).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral300, width: 1.5),
              ),
              child: DropdownButtonFormField<String?>(
                key: ValueKey(selectedEmployeeId),
                initialValue: selectedEmployeeId,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.neutral600),
                ),
                hint: const Text('Seleccionar empleado'),
                isExpanded: true,
                items: [
                  if (showAllOption)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos los empleados'),
                    ),
                  ...activeEmployees.map((employee) {
                    return DropdownMenuItem<String?>(
                      value: employee.id,
                      child: Text(
                        '${employee.nombres} ${employee.apellidos}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error cargando empleados: $e',
          style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
        ),
      ),
    );
  }
}
