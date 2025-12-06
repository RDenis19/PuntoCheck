import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminOrgStaffView extends ConsumerWidget {
  const SuperAdminOrgStaffView({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(organizationStaffProvider(orgId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Equipo'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Todos'),
              Tab(text: 'Admins'),
              Tab(text: 'Managers'),
              Tab(text: 'Empleados'),
            ],
          ),
        ),
        body: SafeArea(
          child: staffAsync.when(
            data: (staff) {
              return TabBarView(
                children: [
                  _StaffList(staff: staff),
                  _StaffList(
                    staff: _filterByRole(staff, {
                      RolUsuario.superAdmin,
                      RolUsuario.orgAdmin,
                    }),
                  ),
                  _StaffList(
                    staff: _filterByRole(staff, {RolUsuario.manager}),
                  ),
                  _StaffList(
                    staff: _filterByRole(staff, {RolUsuario.employee}),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: AppColors.neutral700),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(organizationStaffProvider(orgId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffList extends StatelessWidget {
  const _StaffList({required this.staff});

  final List<Perfiles> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return const Center(
        child: Text(
          'Sin personas en esta categoria',
          style: TextStyle(color: AppColors.neutral700),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final person = staff[index];
        return SectionCard(
          title: '${person.nombres} ${person.apellidos}',
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _roleLabel(person.rol),
                style: const TextStyle(color: AppColors.neutral700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: AppColors.neutral700),
                  const SizedBox(width: 6),
                  Text(person.cargo ?? 'Sin cargo'),
                ],
              ),
              if (person.telefono != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.neutral700),
                    const SizedBox(width: 6),
                    Text(person.telefono!),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    person.activo == true ? Icons.check_circle : Icons.pause_circle,
                    size: 16,
                    color: person.activo == true
                        ? AppColors.successGreen
                        : AppColors.warningOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(person.activo == true ? 'Activo' : 'Inactivo'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Perfiles> _filterByRole(List<Perfiles> staff, Set<RolUsuario> roles) {
  return staff.where((p) => p.rol != null && roles.contains(p.rol!)).toList();
}

String _roleLabel(RolUsuario? rol) {
  switch (rol) {
    case RolUsuario.superAdmin:
      return 'Super Admin';
    case RolUsuario.orgAdmin:
      return 'Org Admin';
    case RolUsuario.manager:
      return 'Manager';
    case RolUsuario.auditor:
      return 'Auditor';
    case RolUsuario.employee:
      return 'Empleado';
    default:
      return 'Sin rol';
  }
}
