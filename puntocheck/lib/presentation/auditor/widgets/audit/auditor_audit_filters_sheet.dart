import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/auditor_audit_providers.dart';

class AuditorAuditFiltersSheet extends StatefulWidget {
  final AuditorAuditLogFilter initial;
  final List<Sucursales> branches;

  const AuditorAuditFiltersSheet({
    super.key,
    required this.initial,
    required this.branches,
  });

  @override
  State<AuditorAuditFiltersSheet> createState() => _AuditorAuditFiltersSheetState();
}

class _AuditorAuditFiltersSheetState extends State<AuditorAuditFiltersSheet> {
  DateTimeRange? _range;
  String? _table;
  String? _actorId;
  String? _branchId;
  RolUsuario? _role;

  final _actionCtrl = TextEditingController();
  final _tableCtrl = TextEditingController();
  final _actorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _range = widget.initial.dateRange;
    _table = widget.initial.table;
    _actorId = widget.initial.actorId;
    _branchId = widget.initial.branchId;
    _role = widget.initial.actorRole;
    _actionCtrl.text = widget.initial.actionQuery;
    _tableCtrl.text = widget.initial.table ?? '';
    _actorCtrl.text = widget.initial.actorId ?? '';
  }

  @override
  void dispose() {
    _actionCtrl.dispose();
    _tableCtrl.dispose();
    _actorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String rangeLabel(DateTimeRange? r) {
      if (r == null) return 'Cualquier fecha';
      String dd(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      return '${dd(r.start)} - ${dd(r.end)}';
    }

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
                      'Filtros de auditoría',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                value: rangeLabel(_range),
                icon: Icons.date_range_rounded,
                onTap: _pickDateRange,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _actionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Acción contiene',
                  hintText: 'Ej: crear perfil, borrar sucursal...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tableCtrl,
                onChanged: (v) => setState(() {
                  _table = v.trim().isEmpty ? null : v.trim();
                }),
                decoration: InputDecoration(
                  labelText: 'Tabla afectada',
                  hintText: 'Ej: perfiles, sucursales...',
                  prefixIcon: const Icon(Icons.table_chart_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: _table == null
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () => setState(() {
                            _table = null;
                            _tableCtrl.clear();
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _actorCtrl,
                onChanged: (v) => setState(() {
                  _actorId = v.trim().isEmpty ? null : v.trim();
                }),
                decoration: InputDecoration(
                  labelText: 'Actor ID (opcional)',
                  hintText: 'UUID de perfiles/auth.users',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: _actorId == null
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () => setState(() {
                            _actorId = null;
                            _actorCtrl.clear();
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sucursal (si aplica)',
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
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Rol del actor',
                  prefixIcon: Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RolUsuario?>(
                    isExpanded: true,
                    value: _role,
                    items: const [
                      DropdownMenuItem<RolUsuario?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<RolUsuario?>(
                        value: RolUsuario.orgAdmin,
                        child: Text('Org Admin'),
                      ),
                      DropdownMenuItem<RolUsuario?>(
                        value: RolUsuario.manager,
                        child: Text('Manager'),
                      ),
                      DropdownMenuItem<RolUsuario?>(
                        value: RolUsuario.employee,
                        child: Text('Empleado'),
                      ),
                      DropdownMenuItem<RolUsuario?>(
                        value: RolUsuario.auditor,
                        child: Text('Auditor'),
                      ),
                      DropdownMenuItem<RolUsuario?>(
                        value: RolUsuario.superAdmin,
                        child: Text('Super Admin'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _role = value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        AuditorAuditLogFilter.initial(),
                      ),
                      child: const Text('Restablecer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        widget.initial.copyWith(
                          dateRange: _range,
                          table: _table,
                          actorId: _actorId,
                          branchId: _branchId,
                          actorRole: _role,
                          actionQuery: _actionCtrl.text.trim(),
                        ),
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
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
