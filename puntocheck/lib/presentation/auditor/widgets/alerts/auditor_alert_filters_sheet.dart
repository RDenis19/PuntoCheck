import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_constants.dart';
import 'package:puntocheck/providers/auditor_providers.dart';

class AuditorAlertFiltersSheet extends StatefulWidget {
  final AuditorAlertsFilter initial;
  final List<Sucursales> branches;

  const AuditorAlertFiltersSheet({
    super.key,
    required this.initial,
    required this.branches,
  });

  @override
  State<AuditorAlertFiltersSheet> createState() => _AuditorAlertFiltersSheetState();
}

class _AuditorAlertFiltersSheetState extends State<AuditorAlertFiltersSheet> {
  String? _status;
  String? _branchId;
  GravedadAlerta? _severity;

  final _typeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _branchId = widget.initial.branchId;
    _severity = widget.initial.severity;
    _typeCtrl.text = widget.initial.typeQuery ?? '';
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      'Filtros de alertas',
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
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.flag_rounded),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _status,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...[
                        for (final s in AuditorAlertConstants.statuses)
                          DropdownMenuItem<String?>(
                            value: s,
                            child: Text(AuditorAlertConstants.statusLabel(s)),
                          ),
                      ],
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                ),
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
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Gravedad',
                  prefixIcon: Icon(Icons.priority_high_rounded),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GravedadAlerta?>(
                    isExpanded: true,
                    value: _severity,
                    items: const [
                      DropdownMenuItem<GravedadAlerta?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      DropdownMenuItem<GravedadAlerta?>(
                        value: GravedadAlerta.leve,
                        child: Text('leve'),
                      ),
                      DropdownMenuItem<GravedadAlerta?>(
                        value: GravedadAlerta.moderada,
                        child: Text('moderada'),
                      ),
                      DropdownMenuItem<GravedadAlerta?>(
                        value: GravedadAlerta.graveLegal,
                        child: Text('grave_legal'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _severity = value),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tipo de alerta',
                  hintText: 'Ej: marcación fuera de geocerca',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        AuditorAlertsFilter.initial().copyWith(query: widget.initial.query),
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
                          status: _status,
                          branchId: _branchId,
                          severity: _severity,
                          typeQuery: _typeCtrl.text.trim().isEmpty
                              ? null
                              : _typeCtrl.text.trim(),
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
}
