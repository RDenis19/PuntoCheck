import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AssignScheduleBulkSheet extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const AssignScheduleBulkSheet({super.key, required this.onDone});

  @override
  ConsumerState<AssignScheduleBulkSheet> createState() =>
      _AssignScheduleBulkSheetState();
}

class _AssignScheduleBulkSheetState
    extends ConsumerState<AssignScheduleBulkSheet> {
  String? _selectedTemplateId;
  String? _selectedBranchId;
  final Set<RolUsuario> _selectedRoles = {RolUsuario.employee};
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedEmployeeIds = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(_templatesProvider);
    final employeesAsync = ref.watch(
      orgAdminStaffProvider(const OrgAdminPeopleFilter(active: true)),
    );
    final branchesAsync = ref.watch(orgAdminBranchesProvider);
    final topInset = MediaQuery.of(context).viewPadding.top;

    final branchNameById = branchesAsync.maybeWhen(
      data: (branches) => {for (final b in branches) b.id: b.nombre},
      orElse: () => <String, String>{},
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 32 + topInset, 20, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Asignacion masiva',
                        style: TextStyle(
                          fontSize: 20,
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
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plantilla de horario',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    templatesAsync.when(
                      data: (templates) {
                        if (templates.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No hay plantillas disponibles. Crea una primero.',
                              style: TextStyle(color: AppColors.warningOrange),
                            ),
                          );
                        }

                        return Column(
                          children: templates.map((t) {
                            final selected = _selectedTemplateId == t.id;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedTemplateId = t.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryRed
                                        : AppColors.neutral300,
                                    width: selected ? 2 : 1.5,
                                  ),
                                  color: selected
                                      ? AppColors.primaryRed.withValues(
                                          alpha: 0.06,
                                        )
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: selected
                                          ? AppColors.primaryRed
                                          : AppColors.neutral600,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        t.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.neutral900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Tol: ${t.toleranciaEntradaMinutos ?? 10}m',
                                      style: const TextStyle(
                                        color: AppColors.neutral700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) =>
                          _ErrorBox(text: 'Error cargando plantillas: $e'),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Rango de fechas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTile(
                            label: 'Inicio',
                            value: _formatDate(_fechaInicio),
                            onTap: () => _selectDate(context, isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateTile(
                            label: 'Fin (opcional)',
                            value: _fechaFin != null
                                ? _formatDate(_fechaFin!)
                                : '--/--/----',
                            onTap: () => _selectDate(context, isStart: false),
                            onClear: _fechaFin == null
                                ? null
                                : () => setState(() => _fechaFin = null),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Empleados',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_selectedEmployeeIds.length} seleccionados',
                            style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    branchesAsync.when(
                      data: (branches) {
                        final activeBranches =
                            branches.where((b) => b.eliminado != true).toList()
                              ..sort((a, b) => a.nombre.compareTo(b.nombre));

                        return DropdownButtonFormField<String?>(
                          key: ValueKey(_selectedBranchId),
                          initialValue: _selectedBranchId,
                          decoration: InputDecoration(
                            labelText: 'Sucursal (opcional)',
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas las sucursales'),
                            ),
                            ...activeBranches.map((Sucursales b) {
                              return DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(b.nombre),
                              );
                            }),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedBranchId = v;
                              _selectedEmployeeIds.clear();
                            });
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) =>
                          _ErrorBox(text: 'Error cargando sucursales: $e'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RoleFilterChip(
                          label: 'Empleados',
                          icon: Icons.badge_outlined,
                          selected: _selectedRoles.contains(
                            RolUsuario.employee,
                          ),
                          onTap: () => _toggleRole(RolUsuario.employee),
                        ),
                        _RoleFilterChip(
                          label: 'Managers',
                          icon: Icons.manage_accounts_outlined,
                          selected: _selectedRoles.contains(RolUsuario.manager),
                          onTap: () => _toggleRole(RolUsuario.manager),
                        ),
                        _RoleFilterChip(
                          label: 'Auditores',
                          icon: Icons.verified_user_outlined,
                          selected: _selectedRoles.contains(RolUsuario.auditor),
                          onTap: () => _toggleRole(RolUsuario.auditor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tip: para seleccionar a todos, deja solo "Empleados".',
                      style: TextStyle(color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o apellido',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    employeesAsync.when(
                      data: (employees) {
                        final base = _applyFilters(employees);
                        final visible = _applySearch(base, _searchCtrl.text);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 0,
                              children: [
                                TextButton.icon(
                                  onPressed: visible.isEmpty
                                      ? null
                                      : () {
                                          setState(() {
                                            for (final e in visible) {
                                              _selectedEmployeeIds.add(e.id);
                                            }
                                          });
                                        },
                                  icon: const Icon(Icons.select_all, size: 18),
                                  label: const Text('Visibles'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed:
                                      _selectedBranchId == null || base.isEmpty
                                      ? null
                                      : () {
                                          setState(() {
                                            for (final e in base) {
                                              _selectedEmployeeIds.add(e.id);
                                            }
                                          });
                                        },
                                  icon: const Icon(
                                    Icons.storefront_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Sucursal'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _selectedEmployeeIds.isEmpty
                                      ? null
                                      : () => setState(
                                          _selectedEmployeeIds.clear,
                                        ),
                                  icon: const Icon(Icons.clear_all, size: 18),
                                  label: const Text('Limpiar'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 360),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.neutral200,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: visible.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No hay empleados con ese filtro.',
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: visible.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final employee = visible[index];
                                        final isSelected = _selectedEmployeeIds
                                            .contains(employee.id);
                                        final branchName =
                                            employee.sucursalId != null
                                            ? branchNameById[employee
                                                  .sucursalId!]
                                            : null;
                                        final roleLabel = _roleLabel(
                                          employee.rol,
                                        );
                                        final subtitleParts = <String>[
                                          if (branchName != null &&
                                              branchName.isNotEmpty)
                                            branchName,
                                          if (employee.cargo != null &&
                                              employee.cargo!.isNotEmpty)
                                            employee.cargo!,
                                          if (roleLabel != null) roleLabel,
                                        ];
                                        return CheckboxListTile(
                                          value: isSelected,
                                          onChanged: (_) => setState(() {
                                            if (isSelected) {
                                              _selectedEmployeeIds.remove(
                                                employee.id,
                                              );
                                            } else {
                                              _selectedEmployeeIds.add(
                                                employee.id,
                                              );
                                            }
                                          }),
                                          title: Text(
                                            '${employee.nombres} ${employee.apellidos}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: subtitleParts.isEmpty
                                              ? null
                                              : Text(
                                                  subtitleParts.join(' | '),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                          dense: true,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                        );
                                      },
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
                      error: (e, _) =>
                          _ErrorBox(text: 'Error cargando empleados: $e'),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Asignar a seleccionados'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleRole(RolUsuario role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }

      if (_selectedRoles.isEmpty) {
        _selectedRoles.add(RolUsuario.employee);
      }

      _selectedEmployeeIds.clear();
    });
  }

  List<Perfiles> _applyFilters(List<Perfiles> employees) {
    final filtered = employees
        .where((e) => e.activo == true)
        .where(
          (e) => e.rol != RolUsuario.superAdmin && e.rol != RolUsuario.orgAdmin,
        )
        .where((e) => e.rol != null && _selectedRoles.contains(e.rol!))
        .where(
          (e) => _selectedBranchId == null || e.sucursalId == _selectedBranchId,
        )
        .toList();

    filtered.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    return filtered;
  }

  List<Perfiles> _applySearch(List<Perfiles> employees, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return employees;

    return employees.where((e) {
      final full = e.nombreCompleto.toLowerCase();
      return full.contains(q);
    }).toList();
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

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _fechaInicio : (_fechaFin ?? DateTime.now()),
      firstDate: isStart ? DateTime.now() : _fechaInicio,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
          if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _save() async {
    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una plantilla de horario')),
      );
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un empleado')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizacionId;
      if (orgId == null) throw Exception('No org ID');

      final startStr = _fechaInicio.toIso8601String().split('T').first;
      final endStr = (_fechaFin ?? DateTime(9999, 12, 31))
          .toIso8601String()
          .split('T')
          .first;

      final overlaps = await supabase
          .from('asignaciones_horarios')
          .select('perfil_id')
          .eq('organizacion_id', orgId)
          .inFilter('perfil_id', _selectedEmployeeIds.toList())
          .lte('fecha_inicio', endStr)
          .or('fecha_fin.is.null,fecha_fin.gte.$startStr');

      final conflicted = (overlaps as List)
          .map((e) => (e['perfil_id']).toString())
          .toSet();

      final toInsert = _selectedEmployeeIds.difference(conflicted).toList();

      if (toInsert.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo asignar: todos los empleados seleccionados tienen un horario que se cruza con esas fechas.',
            ),
          ),
        );
        return;
      }

      if (conflicted.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hay cruces de fechas'),
            content: Text(
              '${conflicted.length} empleados ya tienen un horario que se cruza con este rango. '
              'Se asignara solo a ${toInsert.length} empleados restantes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }

      final payload = toInsert.map((employeeId) {
        return {
          'perfil_id': employeeId,
          'organizacion_id': orgId,
          'plantilla_id': _selectedTemplateId,
          'fecha_inicio': startStr,
          if (_fechaFin != null)
            'fecha_fin': _fechaFin!.toIso8601String().split('T').first,
        };
      }).toList();

      await supabase.from('asignaciones_horarios').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Horario asignado a ${toInsert.length} empleados'
            '${conflicted.isEmpty ? '' : ' (omitidos ${conflicted.length} por cruce)'}',
          ),
        ),
      );
      widget.onDone();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en asignacion masiva: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral300, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.neutral900,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: 'Limpiar',
              ),
          ],
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

class _RoleFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 18),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      side: BorderSide(
        color: selected ? AppColors.primaryRed : AppColors.neutral300,
        width: selected ? 2 : 1.5,
      ),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
        color: selected ? AppColors.primaryRed : AppColors.neutral700,
      ),
    );
  }
}

final _templatesProvider = FutureProvider.autoDispose<List<PlantillasHorarios>>(
  (ref) async {
    final profile = await ref.watch(profileProvider.future);
    final orgId = profile?.organizacionId;
    if (orgId == null) throw Exception('No org ID');
    return ScheduleService.instance.getScheduleTemplates(orgId);
  },
);
