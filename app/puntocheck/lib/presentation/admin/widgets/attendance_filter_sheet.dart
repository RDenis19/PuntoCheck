import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/admin/widgets/branch_selector.dart';
import 'package:puntocheck/presentation/admin/widgets/employee_selector.dart';
import 'package:puntocheck/presentation/shared/models/attendance_filters.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Bottom sheet para filtros avanzados de asistencia
class AttendanceFilterSheet extends StatefulWidget {
  final AttendanceFilters? initialFilters;
  final Function(AttendanceFilters) onApply;

  const AttendanceFilterSheet({
    super.key,
    this.initialFilters,
    required this.onApply,
  });

  @override
  State<AttendanceFilterSheet> createState() => _AttendanceFilterSheetState();
}

class _AttendanceFilterSheetState extends State<AttendanceFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _employeeId;
  late String? _branchId;
  late Set<String> _selectedTypes;
  late bool? _insideGeofence;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilters?.startDate;
    _endDate = widget.initialFilters?.endDate;
    _employeeId = widget.initialFilters?.employeeId;
    _branchId = widget.initialFilters?.branchId;
    _selectedTypes = widget.initialFilters?.types?.toSet() ?? {};
    _insideGeofence = widget.initialFilters?.insideGeofence;
  }

  @override
  Widget build(BuildContext context) {
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
                        Icons.filter_list_rounded,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filtros Avanzados',
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
                    // Rango de fechas
                    const Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Desde',
                            date: _startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Hasta',
                            date: _endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Empleado
                    EmployeeSelector(
                      label: 'Empleado',
                      selectedEmployeeId: _employeeId,
                      onChanged: (value) {
                        setState(() => _employeeId = value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Sucursal
                    BranchSelector(
                      label: 'Sucursal',
                      selectedBranchId: _branchId,
                      onChanged: (value) {
                        setState(() => _branchId = value);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Tipo de registro
                    const Text(
                      'Tipo de Registro',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TypeChip(
                          label: 'Entrada',
                          isSelected: _selectedTypes.contains('entrada'),
                          onTap: () => _toggleType('entrada'),
                        ),
                        _TypeChip(
                          label: 'Salida',
                          isSelected: _selectedTypes.contains('salida'),
                          onTap: () => _toggleType('salida'),
                        ),
                        _TypeChip(
                          label: 'Inicio Break',
                          isSelected: _selectedTypes.contains('inicio_break'),
                          onTap: () => _toggleType('inicio_break'),
                        ),
                        _TypeChip(
                          label: 'Fin Break',
                          isSelected: _selectedTypes.contains('fin_break'),
                          onTap: () => _toggleType('fin_break'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Geocerca
                    const Text(
                      'Estado de Geocerca',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GeofenceOption(
                            label: 'Todos',
                            isSelected: _insideGeofence == null,
                            onTap: () => setState(() => _insideGeofence = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GeofenceOption(
                            label: 'Dentro',
                            isSelected: _insideGeofence == true,
                            onTap: () => setState(() => _insideGeofence = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GeofenceOption(
                            label: 'Fuera',
                            isSelected: _insideGeofence == false,
                            onTap: () =>
                                setState(() => _insideGeofence = false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Aplicar Filtros'),
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

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _employeeId = null;
      _branchId = null;
      _selectedTypes.clear();
      _insideGeofence = null;
    });
  }

  void _applyFilters() {
    final filters = AttendanceFilters(
      startDate: _startDate,
      endDate: _endDate,
      employeeId: _employeeId,
      branchId: _branchId,
      types: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
      insideGeofence: _insideGeofence,
    );
    widget.onApply(filters);
    Navigator.pop(context);
  }
}

// Widgets auxiliares
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date!) : 'Seleccionar',
              style: TextStyle(
                fontWeight: date != null ? FontWeight.w700 : FontWeight.w500,
                color: date != null
                    ? AppColors.neutral900
                    : AppColors.neutral500,
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primaryRed,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryRed : AppColors.neutral700,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _GeofenceOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GeofenceOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.neutral300,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primaryRed : AppColors.neutral700,
          ),
        ),
      ),
    );
  }
}
