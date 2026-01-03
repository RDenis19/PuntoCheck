import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/auditor_providers.dart';

class AuditorAttendanceFiltersSheet extends StatefulWidget {
  final AuditorAttendanceFilter initial;
  final List<Sucursales> branches;

  const AuditorAttendanceFiltersSheet({
    super.key,
    required this.initial,
    required this.branches,
  });

  @override
  State<AuditorAttendanceFiltersSheet> createState() =>
      _AuditorAttendanceFiltersSheetState();
}

class _AuditorAttendanceFiltersSheetState
    extends State<AuditorAttendanceFiltersSheet> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  DateTimeRange? _range;
  String? _branchId;
  bool _geofenceOnly = false;
  bool _mockOnly = false;

  @override
  void initState() {
    super.initState();
    _range = widget.initial.dateRange;
    _branchId = widget.initial.branchId;
    _geofenceOnly = widget.initial.onlyGeofenceIssues;
    _mockOnly = widget.initial.onlyMockLocation;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeLabel = _range == null
        ? 'Cualquier fecha'
        : '${_dateFmt.format(_range!.start)} - ${_dateFmt.format(_range!.end)}';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Filtros de asistencia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FilterTile(
                label: 'Rango de fechas',
                value: rangeLabel,
                icon: Icons.date_range_rounded,
                onTap: _pickDateRange,
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sucursal',
                  prefixIcon: Icon(Icons.store_rounded),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _branchId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...widget.branches.map(
                        (b) => DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.nombre),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _branchId = value),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: _geofenceOnly,
                onChanged: (v) => setState(() => _geofenceOnly = v),
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo fuera de geocerca'),
                subtitle: const Text('Registros fuera del perímetro'),
              ),
              SwitchListTile.adaptive(
                value: _mockOnly,
                onChanged: (v) => setState(() => _mockOnly = v),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ubicación simulada'),
                subtitle: const Text('Apps de GPS falso detectadas'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          AuditorAttendanceFilter.initial().copyWith(query: widget.initial.query),
                        );
                      },
                      child: const Text('Restablecer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          widget.initial.copyWith(
                            dateRange: _range,
                            branchId: _branchId,
                            onlyGeofenceIssues: _geofenceOnly,
                            onlyMockLocation: _mockOnly,
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 6),
          ),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('es'),
    );

    if (!mounted) return;
    if (picked == null) return;
    setState(() => _range = picked);
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }
}
