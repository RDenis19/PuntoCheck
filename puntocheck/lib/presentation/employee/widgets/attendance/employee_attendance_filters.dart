import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/services/attendance_summary_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AttendanceFilters {
  final DateTimeRange? range;
  final AttendanceTypeFilter type;
  final AttendanceGeofenceFilter geofence;
  final bool onlyIncompleteDays;

  const AttendanceFilters({
    this.range,
    this.type = AttendanceTypeFilter.all,
    this.geofence = AttendanceGeofenceFilter.all,
    this.onlyIncompleteDays = false,
  });

  bool get isDefault =>
      range == null &&
      type == AttendanceTypeFilter.all &&
      geofence == AttendanceGeofenceFilter.all &&
      onlyIncompleteDays == false;

  List<RegistrosAsistencia> apply(List<RegistrosAsistencia> input) {
    Iterable<RegistrosAsistencia> out = input;

    if (range != null) {
      out = out.where((r) {
        final t = r.fechaHoraMarcacion;
        final endInclusive = range!.end.add(const Duration(days: 1));
        return !t.isBefore(range!.start) && t.isBefore(endInclusive);
      });
    }

    if (type != AttendanceTypeFilter.all) {
      out = out.where((r) {
        final t = (r.tipoRegistro ?? '').trim();
        switch (type) {
          case AttendanceTypeFilter.entrada:
            return t == 'entrada';
          case AttendanceTypeFilter.salida:
            return t == 'salida';
          case AttendanceTypeFilter.breaks:
            return t == 'inicio_break' || t == 'fin_break';
          case AttendanceTypeFilter.all:
            return true;
        }
      });
    }

    if (geofence != AttendanceGeofenceFilter.all) {
      out = out.where((r) {
        final inside = r.estaDentroGeocerca;
        if (inside == null) return false;
        return geofence == AttendanceGeofenceFilter.inside ? inside : !inside;
      });
    }

    final list = out.toList();
    if (!onlyIncompleteDays) return list;

    final days = AttendanceSummaryHelper.groupByDay(list);
    final keep = days.where((d) => d.isIncomplete).map((d) => d.day).toSet();
    return list
        .where(
          (r) => keep.contains(AttendanceSummaryHelper.dateOnly(r.fechaHoraMarcacion)),
        )
        .toList();
  }
}

enum AttendanceTypeFilter { all, entrada, salida, breaks }

enum AttendanceGeofenceFilter { all, inside, outside }

class EmployeeAttendanceFiltersSheet extends StatefulWidget {
  final AttendanceFilters initial;
  const EmployeeAttendanceFiltersSheet({super.key, required this.initial});

  @override
  State<EmployeeAttendanceFiltersSheet> createState() =>
      _EmployeeAttendanceFiltersSheetState();
}

class _EmployeeAttendanceFiltersSheetState
    extends State<EmployeeAttendanceFiltersSheet> {
  late DateTimeRange? _range = widget.initial.range;
  late AttendanceTypeFilter _type = widget.initial.type;
  late AttendanceGeofenceFilter _geofence = widget.initial.geofence;
  late bool _onlyIncomplete = widget.initial.onlyIncompleteDays;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _RangePickerTile(
                range: _range,
                onPick: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1, 1, 1),
                    lastDate: DateTime(now.year + 1, 12, 31),
                    initialDateRange: _range,
                  );
                  if (picked == null) return;
                  setState(() => _range = picked);
                },
                onClear: () => setState(() => _range = null),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AttendanceTypeFilter>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AttendanceTypeFilter.all,
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: AttendanceTypeFilter.entrada,
                    child: Text('Entradas'),
                  ),
                  DropdownMenuItem(
                    value: AttendanceTypeFilter.salida,
                    child: Text('Salidas'),
                  ),
                  DropdownMenuItem(
                    value: AttendanceTypeFilter.breaks,
                    child: Text('Breaks'),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AttendanceGeofenceFilter>(
                key: ValueKey(_geofence),
                initialValue: _geofence,
                decoration: const InputDecoration(
                  labelText: 'Geocerca',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AttendanceGeofenceFilter.all,
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: AttendanceGeofenceFilter.inside,
                    child: Text('Dentro'),
                  ),
                  DropdownMenuItem(
                    value: AttendanceGeofenceFilter.outside,
                    child: Text('Fuera'),
                  ),
                ],
                onChanged: (v) => setState(() => _geofence = v ?? _geofence),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo días incompletos'),
                subtitle: const Text('Entrada sin salida o break sin cerrar'),
                value: _onlyIncomplete,
                onChanged: (v) => setState(() => _onlyIncomplete = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _range = null;
                        _type = AttendanceTypeFilter.all;
                        _geofence = AttendanceGeofenceFilter.all;
                        _onlyIncomplete = false;
                      }),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          AttendanceFilters(
                            range: _range,
                            type: _type,
                            geofence: _geofence,
                            onlyIncompleteDays: _onlyIncomplete,
                          ),
                        );
                      },
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

class EmployeeAttendanceActiveFiltersBar extends StatelessWidget {
  const EmployeeAttendanceActiveFiltersBar({
    super.key,
    required this.filters,
    required this.onEdit,
    required this.onClear,
  });

  final AttendanceFilters filters;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (filters.isDefault) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: const Row(
            children: [
              Icon(Icons.tune, color: AppColors.neutral700),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sin filtros (toca para filtrar)',
                  style: TextStyle(color: AppColors.neutral700),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, color: AppColors.neutral700),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (filters.range != null) const _Chip(text: 'Rango'),
                if (filters.type != AttendanceTypeFilter.all)
                  _Chip(text: _typeLabel(filters.type)),
                if (filters.geofence != AttendanceGeofenceFilter.all)
                  _Chip(
                    text: filters.geofence == AttendanceGeofenceFilter.inside
                        ? 'Dentro'
                        : 'Fuera',
                  ),
                if (filters.onlyIncompleteDays) const _Chip(text: 'Incompletos'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar filtros',
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppColors.neutral700),
          ),
          IconButton(
            tooltip: 'Limpiar filtros',
            onPressed: onClear,
            icon: const Icon(Icons.close, color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(AttendanceTypeFilter type) {
    switch (type) {
      case AttendanceTypeFilter.entrada:
        return 'Entradas';
      case AttendanceTypeFilter.salida:
        return 'Salidas';
      case AttendanceTypeFilter.breaks:
        return 'Breaks';
      case AttendanceTypeFilter.all:
        return 'Todos';
    }
  }
}

class EmployeeAttendanceNoResultsView extends StatelessWidget {
  const EmployeeAttendanceNoResultsView({super.key, required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sin resultados',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No hay registros para los filtros seleccionados.',
                style: TextStyle(color: AppColors.neutral700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar filtros'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmployeeAttendanceErrorView extends StatelessWidget {
  const EmployeeAttendanceErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: AppColors.errorRed)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangePickerTile extends StatelessWidget {
  const _RangePickerTile({
    required this.range,
    required this.onPick,
    required this.onClear,
  });

  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final text = range == null
        ? 'Cualquier fecha'
        : '${fmt.format(range!.start)} → ${fmt.format(range!.end)}';

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: AppColors.neutral700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rango de fechas',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(color: AppColors.neutral700)),
                ],
              ),
            ),
            if (range != null)
              IconButton(
                tooltip: 'Quitar rango',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral700,
        ),
      ),
    );
  }
}

