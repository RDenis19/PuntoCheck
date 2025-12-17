import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/shared/models/attendance_filters.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ManagerAttendanceFilterSheet extends ConsumerStatefulWidget {
  final AttendanceFilters? initialFilters;
  final ValueChanged<AttendanceFilters> onApply;

  const ManagerAttendanceFilterSheet({
    super.key,
    this.initialFilters,
    required this.onApply,
  });

  @override
  ConsumerState<ManagerAttendanceFilterSheet> createState() =>
      _ManagerAttendanceFilterSheetState();
}

class _ManagerAttendanceFilterSheetState
    extends ConsumerState<ManagerAttendanceFilterSheet> {
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
    final branchesAsync = ref.watch(managerBranchesProvider);
    final employeesAsync = ref.watch(managerTeamProvider(null));

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
                      'Filtros',
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
                    const Text(
                      'Rango de fechas',
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
                            onTap: () => _pickDate(
                              label: 'Desde',
                              initial: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              onPicked: (d) => setState(() {
                                _startDate = d;
                                if (_endDate != null && _endDate!.isBefore(d)) {
                                  _endDate = d;
                                }
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'Hasta',
                            date: _endDate,
                            onTap: () => _pickDate(
                              label: 'Hasta',
                              initial:
                                  _endDate ?? (_startDate ?? DateTime.now()),
                              firstDate: _startDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                              onPicked: (d) => setState(() => _endDate = d),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    branchesAsync.when(
                      data: (branches) => _PickerField(
                        label: 'Sucursal',
                        valueText: _branchLabel(branches, _branchId),
                        icon: Icons.store_mall_directory_outlined,
                        onTap: () async {
                          final picked = await _pickBranch(context, branches);
                          if (picked != null) {
                            setState(() => _branchId = picked);
                          }
                        },
                        onClear: _branchId == null
                            ? null
                            : () => setState(() => _branchId = null),
                      ),
                      loading: () => const _PickerField.loading(
                        label: 'Sucursal',
                        icon: Icons.store_mall_directory_outlined,
                      ),
                      error: (e, _) => _PickerField.error(
                        label: 'Sucursal',
                        icon: Icons.store_mall_directory_outlined,
                        message: '$e',
                      ),
                    ),
                    const SizedBox(height: 12),
                    employeesAsync.when(
                      data: (employees) => _PickerField(
                        label: 'Empleado',
                        valueText: _employeeLabel(employees, _employeeId),
                        icon: Icons.person_outline,
                        onTap: () async {
                          final picked = await _pickEmployee(
                            context,
                            employees,
                          );
                          if (picked != null) {
                            setState(() => _employeeId = picked);
                          }
                        },
                        onClear: _employeeId == null
                            ? null
                            : () => setState(() => _employeeId = null),
                      ),
                      loading: () => const _PickerField.loading(
                        label: 'Empleado',
                        icon: Icons.person_outline,
                      ),
                      error: (e, _) => _PickerField.error(
                        label: 'Empleado',
                        icon: Icons.person_outline,
                        message: '$e',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tipo de registro',
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
                    const Text(
                      'Estado de geocerca',
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearAll,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neutral700,
                              side: const BorderSide(
                                color: AppColors.neutral300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _apply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Aplicar'),
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

  void _clearAll() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _employeeId = null;
      _branchId = null;
      _selectedTypes = {};
      _insideGeofence = null;
    });
  }

  void _apply() {
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

  Future<void> _pickDate({
    required String label,
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
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
      onPicked(picked);
    }
  }

  static String _branchLabel(List<Sucursales> branches, String? id) {
    if (id == null) return 'Todas';
    final found = branches.where((b) => b.id == id).toList();
    return found.isEmpty ? 'Sucursal' : found.first.nombre;
  }

  static String _employeeLabel(List<Perfiles> employees, String? id) {
    if (id == null) return 'Todos';
    final found = employees.where((e) => e.id == id).toList();
    return found.isEmpty ? 'Empleado' : found.first.nombreCompleto;
  }

  Future<String?> _pickBranch(BuildContext context, List<Sucursales> branches) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectionSheet<Sucursales>(
        title: 'Seleccionar sucursal',
        items: branches,
        getId: (b) => b.id,
        getLabel: (b) => b.nombre,
        selectedId: _branchId,
      ),
    );
  }

  Future<String?> _pickEmployee(
    BuildContext context,
    List<Perfiles> employees,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectionSheet<Perfiles>(
        title: 'Seleccionar empleado',
        items: employees,
        getId: (e) => e.id,
        getLabel: (e) => e.nombreCompleto,
        selectedId: _employeeId,
      ),
    );
  }
}

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
    final text = date == null ? '--/--/----' : _format(date!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
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
                      fontSize: 12,
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
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

  static String _format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String valueText;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? errorMessage;
  final bool isLoading;

  const _PickerField({
    required this.label,
    required this.valueText,
    required this.icon,
    required this.onTap,
    this.onClear,
  }) : errorMessage = null,
       isLoading = false;

  const _PickerField.loading({required this.label, required this.icon})
    : valueText = 'Cargando...',
      onTap = _noop,
      onClear = null,
      errorMessage = null,
      isLoading = true;

  const _PickerField.error({
    required this.label,
    required this.icon,
    required String message,
  }) : valueText = 'No disponible',
       onTap = _noop,
       onClear = null,
       errorMessage = message,
       isLoading = false;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading || errorMessage != null ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.neutral700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: errorMessage != null
                          ? AppColors.errorRed
                          : AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.errorRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 18),
                splashRadius: 18,
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.12)
              : AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isSelected ? AppColors.primaryRed : AppColors.neutral700,
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.12)
              : AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.neutral300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: isSelected ? AppColors.primaryRed : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getId;
  final String Function(T) getLabel;
  final String? selectedId;

  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.getId,
    required this.getLabel,
    this.selectedId,
  });

  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      if (_query.isEmpty) return true;
      return widget.getLabel(item).toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.neutral200),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final id = widget.getId(item);
                  final selected = widget.selectedId == id;
                  return ListTile(
                    title: Text(
                      widget.getLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryRed,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
