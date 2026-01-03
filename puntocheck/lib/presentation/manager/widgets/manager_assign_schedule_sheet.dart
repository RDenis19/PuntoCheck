import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerAssignScheduleSheet extends ConsumerStatefulWidget {
  final VoidCallback onAssigned;
  final String? preselectedEmployeeId;
  final Map<String, dynamic>? existingSchedule;

  const ManagerAssignScheduleSheet({
    super.key,
    required this.onAssigned,
    this.preselectedEmployeeId,
    this.existingSchedule,
  });

  @override
  ConsumerState<ManagerAssignScheduleSheet> createState() =>
      _ManagerAssignScheduleSheetState();
}

class _ManagerAssignScheduleSheetState
    extends ConsumerState<ManagerAssignScheduleSheet> {
  bool _assignAllInBranch = false;
  String? _selectedBranchId;
  String? _selectedEmployeeId;
  String? _selectedTemplateId;
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  bool get _isEditing => widget.existingSchedule != null;
  bool get _canBulkAssign =>
      !_isEditing && widget.preselectedEmployeeId == null;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployeeId != null) {
      _selectedEmployeeId = widget.preselectedEmployeeId;
    }

    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _selectedEmployeeId = schedule['perfil_id'] as String?;
      _selectedTemplateId = schedule['plantilla_id'] as String?;
      _fechaInicio = DateTime.parse(schedule['fecha_inicio'] as String);
      if (schedule['fecha_fin'] != null) {
        _fechaFin = DateTime.parse(schedule['fecha_fin'] as String);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(managerScheduleTemplatesProvider);
    final teamAsync = ref.watch(managerTeamProvider(null));
    final branchesAsync = ref.watch(managerBranchesProvider);
    final isSaving = ref.watch(managerScheduleControllerProvider).isLoading;

    final branches = branchesAsync.valueOrNull ?? const <Sucursales>[];
    if (_canBulkAssign && _selectedBranchId == null && branches.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedBranchId = branches.first.id);
      });
    }

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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: AppColors.primaryRed),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Editar Horario' : 'Asignar Horario',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_canBulkAssign)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group_rounded,
                              color: AppColors.neutral700,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Asignar a todos los empleados de una sucursal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ),
                            Switch(
                              value: _assignAllInBranch,
                              activeThumbColor: AppColors.primaryRed,
                              onChanged: isSaving
                                  ? null
                                  : (v) => setState(() {
                                        _assignAllInBranch = v;
                                        if (v) _selectedEmployeeId = null;
                                      }),
                            ),
                          ],
                        ),
                      ),
                    if (_canBulkAssign && branches.length > 1) ...[
                      const Text(
                        'Sucursal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedBranchId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.neutral100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.neutral300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.store_mall_directory_rounded,
                            color: AppColors.neutral600,
                          ),
                        ),
                        hint: const Text('Seleccionar sucursal'),
                        isExpanded: true,
                        items: branches
                            .map(
                              (b) => DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(
                                  b.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _selectedBranchId = v),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      'Empleado',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: teamAsync.when(
                        data: (List<Perfiles> team) {
                          final filtered = _filterTeamByBranch(team);
                          final active = filtered
                              .where((p) => p.activo != false)
                              .toList();

                          if (_assignAllInBranch) {
                            return Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    color: AppColors.neutral600,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      active.isEmpty
                                          ? 'No hay empleados activos en esta sucursal'
                                          : 'Se asignará a ${active.length} empleados activos',
                                      style: const TextStyle(
                                        color: AppColors.neutral700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (active.isEmpty) return const SizedBox();
                          return DropdownButtonFormField<String?>(
                            initialValue: _selectedEmployeeId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                color: AppColors.neutral600,
                              ),
                            ),
                            hint: const Text('Seleccionar empleado'),
                            isExpanded: true,
                            items: active
                                .map(
                                  (empleado) => DropdownMenuItem<String?>(
                                    value: empleado.id,
                                    child: Text(
                                      empleado.nombreCompleto,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: widget.preselectedEmployeeId != null ||
                                    _isEditing
                                ? null
                                : (value) => setState(
                                      () => _selectedEmployeeId = value,
                                    ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) =>
                            const Text('Error al cargar equipo', style: TextStyle(color: AppColors.errorRed)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Plantilla de Horario',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: templatesAsync.when(
                        data: (templates) => DropdownButtonFormField<String?>(
                          initialValue: _selectedTemplateId,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.schedule_rounded,
                                color: AppColors.neutral600),
                          ),
                          hint: const Text('Seleccionar plantilla'),
                          isExpanded: true,
                          items: templates
                              .map(
                                (template) => DropdownMenuItem<String?>(
                                  value: template.id,
                                  child: Text(
                                    template.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedTemplateId = value),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Error: $e',
                            style: const TextStyle(
                                color: AppColors.errorRed, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha Inicio',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _fechaInicio,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() => _fechaInicio = date);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral100,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.neutral300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 18,
                                          color: AppColors.neutral600),
                                      const SizedBox(width: 8),
                                      Text(DateFormat('dd/MM/yyyy')
                                          .format(_fechaInicio)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha Fin (Opcional)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _fechaFin ??
                                        _fechaInicio.add(
                                            const Duration(days: 30)),
                                    firstDate: _fechaInicio,
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 2)),
                                  );
                                  if (date != null) {
                                    setState(() => _fechaFin = date);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral100,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.neutral300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_available_rounded,
                                          size: 18,
                                          color: AppColors.neutral600),
                                      const SizedBox(width: 8),
                                      Text(_fechaFin != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_fechaFin!)
                                          : 'Indefinido'),
                                      if (_fechaFin != null) ...[
                                        const Spacer(),
                                        InkWell(
                                          onTap: () =>
                                              setState(() => _fechaFin = null),
                                          child: const Icon(Icons.close_rounded,
                                              size: 16),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isEditing
                                    ? 'Actualizar Horario'
                                    : 'Asignar Horario',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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

  Future<void> _saveAssignment() async {
    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos requeridos'),
        ),
      );
      return;
    }

    final controller = ref.read(managerScheduleControllerProvider.notifier);

    try {
      if (_isEditing) {
        if (_selectedEmployeeId == null) {
          throw Exception('Selecciona un empleado');
        }
        await controller.updateSchedule(
          assignmentId: widget.existingSchedule!['id'] as String,
          templateId: _selectedTemplateId!,
          startDate: _fechaInicio,
          endDate: _fechaFin,
        );
      } else {
        if (_assignAllInBranch) {
          final employeeIds = await _resolveBranchEmployeeIds();
          if (employeeIds.isEmpty) {
            throw Exception('No hay empleados activos para asignar');
          }
          await controller.assignScheduleBulk(
            employeeIds: employeeIds,
            templateId: _selectedTemplateId!,
            startDate: _fechaInicio,
            endDate: _fechaFin,
          );
        } else {
          if (_selectedEmployeeId == null) {
            throw Exception('Selecciona un empleado');
          }
          await controller.assignSchedule(
            employeeId: _selectedEmployeeId!,
            templateId: _selectedTemplateId!,
            startDate: _fechaInicio,
            endDate: _fechaFin,
          );
        }
      }

      final state = ref.read(managerScheduleControllerProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Error desconocido');
      }

      widget.onAssigned();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Horario actualizado exitosamente'
                : _assignAllInBranch
                    ? 'Horario asignado al equipo'
                    : 'Horario asignado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  List<Perfiles> _filterTeamByBranch(List<Perfiles> team) {
    if (!_canBulkAssign) return team;
    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) return team;
    return team.where((p) => p.sucursalId == branchId).toList();
  }

  Future<List<String>> _resolveBranchEmployeeIds() async {
    final branches = ref.read(managerBranchesProvider).valueOrNull ?? const <Sucursales>[];
    if (branches.isNotEmpty && _selectedBranchId == null && branches.length == 1) {
      _selectedBranchId = branches.first.id;
    }

    final branchId = _selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      throw Exception('Selecciona una sucursal');
    }

    final team = await ref.read(managerTeamProvider(null).future);
    return team
        .where((p) => p.sucursalId == branchId)
        .where((p) => p.activo != false)
        .map((p) => p.id)
        .toList();
  }
}
