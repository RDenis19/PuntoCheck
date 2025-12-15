import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/admin/widgets/assign_schedule_bulk_sheet.dart';
import 'package:puntocheck/presentation/admin/widgets/assign_schedule_sheet.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/providers/org_admin_providers.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

enum _AssignmentListMode { assigned, unassigned }

class _AssignmentsViewFilter {
  final _AssignmentListMode mode;
  final String? branchId;
  final RolUsuario? role;

  const _AssignmentsViewFilter({required this.mode, this.branchId, this.role});

  const _AssignmentsViewFilter.defaults()
    : mode = _AssignmentListMode.assigned,
      branchId = null,
      role = RolUsuario.employee;

  _AssignmentsViewFilter copyWith({
    _AssignmentListMode? mode,
    String? branchId,
    bool clearBranch = false,
    RolUsuario? role,
  }) {
    return _AssignmentsViewFilter(
      mode: mode ?? this.mode,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      role: role ?? this.role,
    );
  }
}

final _assignmentsFilterProvider =
    StateProvider.autoDispose<_AssignmentsViewFilter>(
      (ref) => const _AssignmentsViewFilter.defaults(),
    );

final _filteredAssignmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, _AssignmentsViewFilter>((
      ref,
      filter,
    ) async {
      final profile = await ref.watch(profileProvider.future);
      final orgId = profile?.organizacionId;
      if (orgId == null) throw Exception('No org ID');

      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final response = await supabase
          .from('asignaciones_horarios')
          .select('''
        id, perfil_id, organizacion_id, plantilla_id, fecha_inicio, fecha_fin, creado_en,
        perfiles!inner(id, nombres, apellidos, rol, sucursal_id),
        plantillas_horarios!inner(nombre)
        ''')
          .eq('organizacion_id', orgId)
          .or('fecha_fin.is.null,fecha_fin.gte.$todayStr')
          .order('creado_en', ascending: false);

      final list = List<Map<String, dynamic>>.from(response as List);

      bool allowedRole(String? role) =>
          role == RolUsuario.employee.value ||
          role == RolUsuario.manager.value ||
          role == RolUsuario.auditor.value;

      return list.where((row) {
        final employee = row['perfiles'] as Map<String, dynamic>?;
        if (employee == null) return false;
        final employeeRole = employee['rol']?.toString();
        if (!allowedRole(employeeRole)) return false;

        if (filter.role != null && employeeRole != filter.role!.value)
          return false;
        if (filter.branchId != null &&
            employee['sucursal_id'] != filter.branchId) {
          return false;
        }
        return true;
      }).toList();
    });

final _unassignedEmployeesProvider = FutureProvider.autoDispose
    .family<List<Perfiles>, _AssignmentsViewFilter>((ref, filter) async {
      final profile = await ref.watch(profileProvider.future);
      final orgId = profile?.organizacionId;
      if (orgId == null) throw Exception('No org ID');

      final peopleFilter = OrgAdminPeopleFilter(
        active: true,
        role: filter.role,
        branchId: filter.branchId,
      );

      final staff = await ref.watch(orgAdminStaffProvider(peopleFilter).future);

      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final assignments = await supabase
          .from('asignaciones_horarios')
          .select('perfil_id')
          .eq('organizacion_id', orgId)
          .or('fecha_fin.is.null,fecha_fin.gte.$todayStr');

      final assignedIds = (assignments as List)
          .map((e) => e['perfil_id'].toString())
          .toSet();

      bool allowedRole(RolUsuario? role) =>
          role == RolUsuario.employee ||
          role == RolUsuario.manager ||
          role == RolUsuario.auditor;

      return staff
          .where((p) => allowedRole(p.rol))
          .where((p) => !assignedIds.contains(p.id))
          .toList()
        ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    });

/// Vista para gestionar asignaciones de horarios
class OrgAdminScheduleAssignmentsView extends ConsumerWidget {
  const OrgAdminScheduleAssignmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_assignmentsFilterProvider);
    final branchesAsync = ref.watch(orgAdminBranchesProvider);
    final assignmentsAsync = filter.mode == _AssignmentListMode.assigned
        ? ref.watch(_filteredAssignmentsProvider(filter))
        : const AsyncValue.data(<Map<String, dynamic>>[]);
    final unassignedAsync = filter.mode == _AssignmentListMode.unassigned
        ? ref.watch(_unassignedEmployeesProvider(filter))
        : const AsyncValue.data(<Perfiles>[]);

    final branchNameById = branchesAsync.maybeWhen(
      data: (branches) => {for (final b in branches) b.id: b.nombre},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignaciones de Horarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filtros',
            onPressed: () => _openFilterSheet(context, ref, filter),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(_filteredAssignmentsProvider(filter));
              ref.invalidate(_unassignedEmployeesProvider(filter));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_filteredAssignmentsProvider(filter));
            ref.invalidate(_unassignedEmployeesProvider(filter));
            if (filter.mode == _AssignmentListMode.assigned) {
              await ref.read(_filteredAssignmentsProvider(filter).future);
            } else {
              await ref.read(_unassignedEmployeesProvider(filter).future);
            }
          },
          child: filter.mode == _AssignmentListMode.assigned
              ? assignmentsAsync.when(
                  data: (assignments) {
                    if (assignments.isEmpty) {
                      return EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'Sin asignaciones',
                        subtitle: 'No hay asignaciones con estos filtros.',
                        primaryLabel: 'Asignar Horario',
                        onPrimary: () => _openAssignOptions(context, ref),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = assignments[index];
                        return _AssignmentCard(
                          assignment: assignment,
                          onDelete: () => _deleteAssignment(
                            context,
                            ref,
                            assignment['id'],
                            filter,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  ),
                  error: (error, _) => _ErrorState(
                    title: 'Error cargando asignaciones',
                    error: error,
                    onRetry: () =>
                        ref.invalidate(_filteredAssignmentsProvider(filter)),
                  ),
                )
              : unassignedAsync.when(
                  data: (people) {
                    if (people.isEmpty) {
                      return EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Todos asignados',
                        subtitle:
                            'No hay empleados sin asignacion con estos filtros.',
                        primaryLabel: 'Asignar Horario',
                        onPrimary: () => _openAssignOptions(context, ref),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: people.length,
                      itemBuilder: (context, index) {
                        final p = people[index];
                        return _UnassignedCard(
                          profile: p,
                          branchName: p.sucursalId != null
                              ? branchNameById[p.sucursalId!]
                              : null,
                          roleLabel: _roleLabel(p.rol),
                          onAssign: () =>
                              _openSingleAssign(context, ref, p.id, filter),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  ),
                  error: (error, _) => _ErrorState(
                    title: 'Error cargando faltantes',
                    error: error,
                    onRetry: () =>
                        ref.invalidate(_unassignedEmployeesProvider(filter)),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssignOptions(context, ref),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Asignar Horario'),
      ),
    );
  }

  void _openAssignOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignOptionsSheet(
        onSingle: () {
          Navigator.pop(context);
          _openSingleAssign(
            context,
            ref,
            null,
            ref.read(_assignmentsFilterProvider),
          );
        },
        onBulk: () {
          Navigator.pop(context);
          _openBulkAssign(context, ref);
        },
      ),
    );
  }

  void _openSingleAssign(
    BuildContext context,
    WidgetRef ref,
    String? initialEmployeeId,
    _AssignmentsViewFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignScheduleSheet(
        initialEmployeeId: initialEmployeeId,
        onAssigned: (_) {
          ref.invalidate(_filteredAssignmentsProvider(filter));
          ref.invalidate(_unassignedEmployeesProvider(filter));
        },
      ),
    );
  }

  void _openBulkAssign(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignScheduleBulkSheet(
        onDone: () {
          final filter = ref.read(_assignmentsFilterProvider);
          ref.invalidate(_filteredAssignmentsProvider(filter));
          ref.invalidate(_unassignedEmployeesProvider(filter));
        },
      ),
    );
  }

  void _openFilterSheet(
    BuildContext context,
    WidgetRef ref,
    _AssignmentsViewFilter current,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentsFilterSheet(
        initial: current,
        onApply: (next) {
          ref.read(_assignmentsFilterProvider.notifier).state = next;
        },
      ),
    );
  }

  Future<void> _deleteAssignment(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
    _AssignmentsViewFilter filter,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar asignación'),
        content: const Text(
          '¿Estás seguro de eliminar esta asignación de horario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('asignaciones_horarios')
            .delete()
            .eq('id', assignmentId);

        ref.invalidate(_filteredAssignmentsProvider(filter));
        ref.invalidate(_unassignedEmployeesProvider(filter));

        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Asignación eliminada')));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

String? _roleLabel(RolUsuario? role) {
  switch (role) {
    case RolUsuario.employee:
      return 'Empleado';
    case RolUsuario.manager:
      return 'Manager';
    case RolUsuario.auditor:
      return 'Auditor';
    default:
      return null;
  }
}

class _AssignOptionsSheet extends StatelessWidget {
  final VoidCallback onSingle;
  final VoidCallback onBulk;

  const _AssignOptionsSheet({required this.onSingle, required this.onBulk});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Asignar a un empleado',
                subtitle: 'Selecciona 1 empleado y asigna un horario',
                onTap: onSingle,
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.group_add_rounded,
                title: 'Asignacion masiva',
                subtitle:
                    'Selecciona 20 o 30 empleados y asigna el mismo horario',
                onTap: onBulk,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral600,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onDelete;

  const _AssignmentCard({required this.assignment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final employee = assignment['perfiles'] as Map<String, dynamic>?;
    final template = assignment['plantillas_horarios'] as Map<String, dynamic>?;
    final fechaInicio = DateTime.parse(assignment['fecha_inicio']);
    final fechaFin = assignment['fecha_fin'] != null
        ? DateTime.parse(assignment['fecha_fin'])
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.neutral200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Empleado
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.8),
                        AppColors.primaryRed,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee != null
                            ? '${employee['nombres']} ${employee['apellidos']}'
                            : 'Empleado desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template?['nombre'] ?? 'Sin plantilla',
                        style: const TextStyle(
                          color: AppColors.neutral600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Fechas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desde',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(fechaInicio),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hasta',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fechaFin != null
                              ? _formatDate(fechaFin)
                              : 'Indefinido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: fechaFin != null
                                ? AppColors.neutral900
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _UnassignedCard extends StatelessWidget {
  final Perfiles profile;
  final String? branchName;
  final String? roleLabel;
  final VoidCallback onAssign;

  const _UnassignedCard({
    required this.profile,
    required this.branchName,
    required this.roleLabel,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (branchName != null && branchName!.isNotEmpty) branchName!,
      if (profile.cargo != null && profile.cargo!.isNotEmpty) profile.cargo!,
      if (roleLabel != null) roleLabel!,
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.neutral200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.person_outline, color: AppColors.neutral700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nombreCompleto,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitleParts.join(' | '),
                      style: const TextStyle(color: AppColors.neutral700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.add),
              label: const Text('Asignar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsFilterSheet extends ConsumerStatefulWidget {
  final _AssignmentsViewFilter initial;
  final ValueChanged<_AssignmentsViewFilter> onApply;

  const _AssignmentsFilterSheet({required this.initial, required this.onApply});

  @override
  ConsumerState<_AssignmentsFilterSheet> createState() =>
      _AssignmentsFilterSheetState();
}

class _AssignmentsFilterSheetState
    extends ConsumerState<_AssignmentsFilterSheet> {
  late _AssignmentListMode _mode;
  String? _branchId;
  RolUsuario? _role;

  @override
  void initState() {
    super.initState();
    _mode = widget.initial.mode;
    _branchId = widget.initial.branchId;
    _role = widget.initial.role;
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(orgAdminBranchesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros avanzados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Asignados'),
                    selected: _mode == _AssignmentListMode.assigned,
                    onSelected: (_) =>
                        setState(() => _mode = _AssignmentListMode.assigned),
                  ),
                  ChoiceChip(
                    label: const Text('Sin asignacion'),
                    selected: _mode == _AssignmentListMode.unassigned,
                    onSelected: (_) =>
                        setState(() => _mode = _AssignmentListMode.unassigned),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              branchesAsync.when(
                data: (branches) {
                  final active =
                      branches.where((b) => b.eliminado != true).toList()
                        ..sort((a, b) => a.nombre.compareTo(b.nombre));

                  return DropdownButtonFormField<String?>(
                    value: _branchId,
                    decoration: InputDecoration(
                      labelText: 'Sucursal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...active.map((Sucursales b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.nombre),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    _ErrorBox(text: 'Error cargando sucursales: $e'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RolUsuario?>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem<RolUsuario?>(
                    value: null,
                    child: Text('Todos (empleado/manager/auditor)'),
                  ),
                  DropdownMenuItem<RolUsuario?>(
                    value: RolUsuario.employee,
                    child: Text('Empleados'),
                  ),
                  DropdownMenuItem<RolUsuario?>(
                    value: RolUsuario.manager,
                    child: Text('Managers'),
                  ),
                  DropdownMenuItem<RolUsuario?>(
                    value: RolUsuario.auditor,
                    child: Text('Auditores'),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _mode = _AssignmentListMode.assigned;
                          _branchId = null;
                          _role = RolUsuario.employee;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _AssignmentsViewFilter(
                            mode: _mode,
                            branchId: _branchId,
                            role: _role,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;

  const _ErrorBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.errorRed,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
