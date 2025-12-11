import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/perfiles.dart';
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
  String? _selectedEmployeeId;
  String? _selectedTemplateId;
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  bool get _isEditing => widget.existingSchedule != null;

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
    final isSaving = ref.watch(managerScheduleControllerProvider).isLoading;

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
                      child: const Icon(Icons.calendar_month_outlined,
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
                      icon: const Icon(Icons.close),
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
                    const Text('Empleado',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: teamAsync.when(
                        data: (List<Perfiles> team) {
                          if (team.isEmpty) return const SizedBox();
                          return DropdownButtonFormField<String?>(
                            value: _selectedEmployeeId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.person_outline,
                                  color: AppColors.neutral600),
                            ),
                            hint: const Text('Seleccionar empleado'),
                            isExpanded: true,
                            items: team
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
                                : (value) =>
                                    setState(() => _selectedEmployeeId = value),
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
                          value: _selectedTemplateId,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.schedule_outlined,
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
                                      const Icon(Icons.calendar_today,
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
                                      const Icon(Icons.event_available,
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
                                          child: const Icon(Icons.close,
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
    if (_selectedEmployeeId == null || _selectedTemplateId == null) {
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
        await controller.updateSchedule(
          assignmentId: widget.existingSchedule!['id'] as String,
          templateId: _selectedTemplateId!,
          startDate: _fechaInicio,
          endDate: _fechaFin,
        );
      } else {
        await controller.assignSchedule(
          employeeId: _selectedEmployeeId!,
          templateId: _selectedTemplateId!,
          startDate: _fechaInicio,
          endDate: _fechaFin,
        );
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
}
