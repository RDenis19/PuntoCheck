import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Modal para asignación masiva de horarios.
/// Flujo:
/// 1. Seleccionar Plantilla y Fechas.
/// 2. Seleccionar Empleados (Checkboxes + Bulk).
/// 3. Confirmar.
class ManagerAssignScheduleSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>?
  existingSchedule; // Si viene, es edición (no masiva)
  final String? preselectedEmployeeId;
  final VoidCallback onAssigned;

  const ManagerAssignScheduleSheet({
    super.key,
    this.existingSchedule,
    this.preselectedEmployeeId,
    required this.onAssigned,
  });

  @override
  ConsumerState<ManagerAssignScheduleSheet> createState() =>
      _ManagerAssignScheduleSheetState();
}

class _ManagerAssignScheduleSheetState
    extends ConsumerState<ManagerAssignScheduleSheet> {
  // Step 1: Configurar Horario
  PlantillasHorarios? _selectedTemplate;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final _endDateController = TextEditingController();

  // Step 2: Seleccionar Personas (Solo si no es editing)
  final Set<String> _selectedEmployeeIds = {};
  bool _selectAll = false;
  String _employeeSearch = '';

  // Control
  bool _isEditing = false;
  int _currentStep = 0; // 0: Config, 1: Selection (Solo bulk)

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _isEditing = true;
      // Pre-fill logic for editing (single mode)
      final s = widget.existingSchedule!;
      _startDate = DateTime.parse(s['fecha_inicio']);
      if (s['fecha_fin'] != null) {
        _endDate = DateTime.parse(s['fecha_fin']);
        _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
      }
      // Template load happens via provider, we'll set it when list loads or manually match ID
      // For simplicity, we just assume user re-selects or we match logic in build if needed.
      // But 'plantilla_id' is available: s['plantilla_id']
    } else {
      // Default start date: tomorrow or today? Using today for agility.
      _startDate = DateTime.now();

      if (widget.preselectedEmployeeId != null) {
        _selectedEmployeeIds.add(widget.preselectedEmployeeId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar estado de la mutación
    final state = ref.watch(managerScheduleControllerProvider);
    final templatesAsync = ref.watch(managerScheduleTemplatesProvider);
    final teamAsync = ref.watch(managerTeamProvider(_employeeSearch));

    // Si estamos editando, tratamos de encontrar el template original en la lista
    if (_selectedTemplate == null &&
        _isEditing &&
        templatesAsync.hasValue &&
        widget.existingSchedule != null) {
      final tid = widget.existingSchedule!['plantilla_id'];
      try {
        _selectedTemplate = templatesAsync.value!.firstWhere(
          (t) => t.id == tid,
        );
      } catch (_) {}
    }

    final isLoading = state.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing
                      ? 'Editar Asignación'
                      : (_currentStep == 0
                            ? 'Nueva Asignación'
                            : 'Seleccionar Personal'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : _currentStep == 0
                ? _buildConfigStep(templatesAsync)
                : _buildSelectionStep(teamAsync),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.neutral200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep == 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep = 0),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.neutral300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Atrás',
                          style: TextStyle(color: AppColors.neutral900),
                        ),
                      ),
                    ),
                  if (_currentStep == 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_isEditing) {
                                _submitEdit();
                              } else {
                                if (_currentStep == 0) {
                                  // Validate step 1
                                  if (_selectedTemplate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Selecciona un horario'),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _currentStep = 1);
                                } else {
                                  _submitBulk();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEditing
                            ? 'Guardar Cambios'
                            : (_currentStep == 0
                                  ? 'Siguiente'
                                  : 'Asignar (${_selectedEmployeeIds.length})'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: Configurar Horario y Fechas ---
  Widget _buildConfigStep(AsyncValue<List<PlantillasHorarios>> templatesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector de Plantilla
          const Text(
            'HORARIO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 8),
          templatesAsync.when(
            loading: () =>
                const LinearProgressIndicator(color: AppColors.primaryRed),
            error: (e, _) => Text('Error: $e'),
            data: (templates) {
              if (templates.isEmpty) {
                return const Text('No hay plantillas creadas.');
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PlantillasHorarios>(
                    isExpanded: true,
                    hint: const Text('Selecciona una plantilla'),
                    value: _selectedTemplate,
                    onChanged: (val) {
                      setState(() => _selectedTemplate = val);
                    },
                    items: templates.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          if (_selectedTemplate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_selectedTemplate!.diasLaborales?.length ?? 0} días laborables • ${_selectedTemplate!.esRotativo == true ? "Rotativo" : "Fijo"}',
              style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ],

          const SizedBox(height: 24),

          // 2. Fechas
          const Text(
            'VIGENCIA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Inicio',
                  date: _startDate,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.neutral400,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'Fin (Opcional)',
                  date: _endDate,
                  isOptional: true,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate,
                      firstDate: _startDate,
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _endDate = d);
                  },
                  onClear: _endDate != null
                      ? () => setState(() => _endDate = null)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 2: Selección Masiva de Empleados ---
  Widget _buildSelectionStep(AsyncValue<List<dynamic>> teamAsync) {
    return Column(
      children: [
        // Search & Select All Hook
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _employeeSearch = val),
            decoration: InputDecoration(
              hintText: 'Buscar empleado...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.neutral500,
              ),
              filled: true,
              fillColor: AppColors.neutral100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Lista
        Expanded(
          child: teamAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (team) {
              if (team.isEmpty) {
                return const Center(
                  child: Text('No se encontraron empleados.'),
                );
              }

              // Select All Logic helper inside list header?
              // Let's put a "Select All" CheckboxTile at top
              return Column(
                children: [
                  CheckboxListTile(
                    title: const Text(
                      'Seleccionar Todos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value:
                        _selectAll, // This logic needs refinement: are all filtered selected?
                    activeColor: AppColors.primaryRed,
                    onChanged: (val) {
                      setState(() {
                        _selectAll = val ?? false;
                        if (_selectAll) {
                          _selectedEmployeeIds.addAll(team.map((e) => e.id));
                        } else {
                          // Only clear observable ones or all? Clears all for simplicity
                          _selectedEmployeeIds.clear();
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: team.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final emp = team[index];
                        final isSelected = _selectedEmployeeIds.contains(
                          emp.id,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: AppColors.primaryRed,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedEmployeeIds.add(emp.id);
                              } else {
                                _selectedEmployeeIds.remove(emp.id);
                              }
                              // Update selectAll visual state if needed (skipped for speed)
                            });
                          },
                          title: Text('${emp.nombres} ${emp.apellidos}'),
                          subtitle: Text(emp.cargo ?? 'Sin cargo'),
                          secondary: CircleAvatar(
                            backgroundColor: AppColors.neutral100,
                            backgroundImage: (emp.fotoPerfilUrl != null)
                                ? NetworkImage(emp.fotoPerfilUrl!)
                                : null,
                            child: (emp.fotoPerfilUrl == null)
                                ? Text(emp.nombres[0])
                                : null,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Submit Actions
  Future<void> _submitBulk() async {
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un empleado')),
      );
      return;
    }

    try {
      await ref
          .read(managerScheduleControllerProvider.notifier)
          .assignScheduleBulk(
            employeeIds: _selectedEmployeeIds.toList(),
            templateId: _selectedTemplate!.id,
            startDate: _startDate,
            endDate: _endDate,
          );
      if (mounted) {
        widget.onAssigned();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Horario asignado a ${_selectedEmployeeIds.length} empleados',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _submitEdit() async {
    try {
      // Single Edit Mode
      if (_selectedTemplate == null) return;

      await ref
          .read(managerScheduleControllerProvider.notifier)
          .updateSchedule(
            assignmentId: widget.existingSchedule!['id'],
            templateId: _selectedTemplate!.id,
            startDate: _startDate,
            endDate: _endDate,
          );

      if (mounted) {
        widget.onAssigned();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignación actualizada'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isOptional;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.isOptional = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    String text = 'Indefinido';
    if (date != null) {
      text = DateFormat('dd/MM/yyyy').format(date!);
    } else if (!isOptional) {
      text = 'Seleccionar';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: date == null
                        ? AppColors.neutral400
                        : AppColors.neutral900,
                  ),
                ),
                if (onClear != null && date != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.neutral500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
