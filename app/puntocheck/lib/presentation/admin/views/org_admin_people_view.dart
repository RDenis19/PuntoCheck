import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
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
  bool? _active = true;

  @override
  Widget build(BuildContext context) {
    final filter = OrgAdminPeopleFilter(
      search: _search,
      role: _role,
      active: _active,
    );
    final staffAsync = ref.watch(orgAdminStaffProvider(filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por apellido',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setState(() => _search = value.trim().isEmpty ? null : value),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<RolUsuario?>(
                onSelected: (value) => setState(() => _role = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: null, child: Text('Todos')),
                  PopupMenuItem(
                    value: RolUsuario.manager,
                    child: Text('Manager'),
                  ),
                  PopupMenuItem(
                    value: RolUsuario.auditor,
                    child: Text('Auditor'),
                  ),
                  PopupMenuItem(
                    value: RolUsuario.employee,
                    child: Text('Empleado'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 18),
                      const SizedBox(width: 6),
                      Text(_role?.value ?? 'Rol'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _active == true,
                label: const Text('Activos'),
                onSelected: (_) => setState(() => _active = _active == true ? null : true),
              ),
            ],
          ),
        ),
        Expanded(
          child: staffAsync.when(
            data: (staff) {
              if (staff.isEmpty) {
                return const _EmptyState(
                  icon: Icons.groups_outlined,
                  text: 'No hay personas que coincidan con el filtro.',
                );
              }
              return ListView.separated(
                itemCount: staff.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final perfil = staff[index];
                  return OrgAdminPersonItem(
                    perfil: perfil,
                    onTap: () {
                      // Aquí podrías navegar a un detalle de empleado.
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error cargando personas: $e'),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.neutral500),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
