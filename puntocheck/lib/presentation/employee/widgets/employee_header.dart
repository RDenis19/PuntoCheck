import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/superadmin/widgets/super_admin_header.dart';
import 'package:puntocheck/providers/employee_providers.dart';

class EmployeeHeader extends ConsumerWidget {
  const EmployeeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(employeeProfileProvider);
    final branchesAsync = ref.watch(employeeBranchesProvider);

    return SafeArea(
      bottom: false,
      child: profileAsync.when(
        data: (profile) {
          final branchName = branchesAsync.valueOrNull?.isNotEmpty == true
              ? branchesAsync.valueOrNull!.first.nombre
              : null;

          final fallbackBranchId = (branchName == null &&
                  profile.sucursalId != null &&
                  profile.sucursalId!.isNotEmpty)
              ? profile.sucursalId!.substring(0, 8)
              : null;

          return SuperAdminHeader(
            userName: profile.nombres,
            roleLabel: profile.cargo ?? 'Empleado',
            organizationName: branchName != null
                ? 'Sucursal: $branchName'
                : (fallbackBranchId != null
                    ? 'Sucursal asignada: $fallbackBranchId...'
                    : 'Sucursal: Sin asignar'),
            trailing: IconButton(
              tooltip: 'Actualizar',
              onPressed: () {
                ref
                  ..invalidate(employeeBranchesProvider)
                  ..invalidate(employeeProfileProvider);
              },
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          );
        },
        loading: () => const SuperAdminHeader(
          userName: 'Cargando...',
          roleLabel: '...',
          organizationName: '...',
        ),
        error: (_, __) => const SuperAdminHeader(
          userName: 'Error',
          roleLabel: 'Error',
          organizationName: 'Error',
        ),
      ),
    );
  }
}
