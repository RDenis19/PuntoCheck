import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/asignaciones_horarios.dart';
import 'package:puntocheck/presentation/admin/widgets/employee_selector.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Bottom sheet para asignar un horario a un empleado
class AssignScheduleSheet extends ConsumerStatefulWidget {
  final Function(AsignacionesHorarios) onAssigned;
  final String? initialEmployeeId;

  const AssignScheduleSheet({
    super.key,
    required this.onAssigned,
    this.initialEmployeeId,
  });

  @override
  ConsumerState<AssignScheduleSheet> createState() =>
      _AssignScheduleSheetState();
}

class _AssignScheduleSheetState extends ConsumerState<AssignScheduleSheet> {
  String? _selectedEmployeeId;
  String? _selectedTemplateId;
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.initialEmployeeId;
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(_templatesProvider);

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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Asignar Horario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const Spacer(),
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
                    // Selector de empleado
                    EmployeeSelector(
                      label: 'Empleado',
                      selectedEmployeeId: _selectedEmployeeId,
                      onChanged: (value) {
                        setState(() => _selectedEmployeeId = value);
                      },
                      showAllOption: false,
                    ),

                    const SizedBox(height: 20),

                    // Selector de plantilla
                    const Text(
                      'Plantilla de Horario',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    schedulesAsync.when(
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

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.neutral300,
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonFormField<String?>(
                            value: _selectedTemplateId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.schedule_outlined,
                                color: AppColors.neutral600,
                              ),
                            ),
                            hint: const Text('Seleccionar plantilla'),
                            isExpanded: true,
                            items: templates.map((template) {
                              return DropdownMenuItem<String?>(
                                value: template.id,
                                child: Text(
                                  template.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedTemplateId = value);
                            },
                          ),
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
                          'Error cargando plantillas: $e',
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Fecha de inicio
                    const Text(
                      'Fecha de Inicio',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.neutral300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(_fechaInicio),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Fecha fin (opcional)
                    Row(
                      children: [
                        const Text(
                          'Fecha de Fin (Opcional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const Spacer(),
                        if (_fechaFin != null)
                          TextButton(
                            onPressed: () {
                              setState(() => _fechaFin = null);
                            },
                            child: const Text('Limpiar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context, isStart: false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.neutral300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _fechaFin != null
                                  ? _formatDate(_fechaFin!)
                                  : 'Sin fecha fin (indefinido)',
                              style: TextStyle(
                                fontWeight: _fechaFin != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                                color: _fechaFin != null
                                    ? AppColors.neutral900
                                    : AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                                : const Text('Asignar'),
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
          // Si fecha fin es anterior, limpiarla
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
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un empleado')));
      return;
    }

    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una plantilla de horario')),
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
          .select('id')
          .eq('organizacion_id', orgId)
          .eq('perfil_id', _selectedEmployeeId!)
          .lte('fecha_inicio', endStr)
          .or('fecha_fin.is.null,fecha_fin.gte.$startStr');

      if ((overlaps as List).isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El empleado ya tiene un horario asignado que se cruza con esas fechas. '
              'Cambia el rango o edita la asignación existente.',
            ),
          ),
        );
        return;
      }

      final response = await supabase
          .from('asignaciones_horarios')
          .insert({
            'perfil_id': _selectedEmployeeId,
            'organizacion_id': orgId,
            'plantilla_id': _selectedTemplateId,
            'fecha_inicio': startStr,
            if (_fechaFin != null)
              'fecha_fin': _fechaFin!.toIso8601String().split('T').first,
          })
          .select()
          .single();

      final assignment = AsignacionesHorarios.fromJson(response);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario asignado exitosamente')),
      );
      widget.onAssigned(assignment);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar horario: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// Provider para plantillas
final _templatesProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null) throw Exception('No org ID');
  return ScheduleService.instance.getScheduleTemplates(orgId);
});
