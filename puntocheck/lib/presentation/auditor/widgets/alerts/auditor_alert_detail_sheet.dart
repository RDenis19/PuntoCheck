import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_constants.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAlertDetailSheet extends StatefulWidget {
  final AlertasCumplimiento alert;
  final String? branchName;
  final Future<void> Function({
    required String status,
    required String? justification,
  }) onSave;
  final VoidCallback? onOpenEmployeeAttendance;
  final VoidCallback? onOpenRecord;
  final String? recordLabel;

  const AuditorAlertDetailSheet({
    super.key,
    required this.alert,
    required this.branchName,
    required this.onSave,
    this.onOpenEmployeeAttendance,
    this.onOpenRecord,
    this.recordLabel,
  });

  @override
  State<AuditorAlertDetailSheet> createState() => _AuditorAlertDetailSheetState();
}

class _AuditorAlertDetailSheetState extends State<AuditorAlertDetailSheet> {
  final _justCtrl = TextEditingController();
  bool _saving = false;

  String _status = 'pendiente';

  static final DateFormat _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    final s = (widget.alert.estado ?? 'pendiente').toString().trim();
    _status = AuditorAlertConstants.statuses.contains(s) ? s : 'pendiente';
    _justCtrl.text = (widget.alert.justificacionAdmin ?? '').toString();
  }

  @override
  void dispose() {
    _justCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = AuditorAlertConstants.severityColor(widget.alert.gravedad);
    final created = widget.alert.fechaDeteccion;
    final employee = widget.alert.empleadoNombreCompleto ?? 'Sin empleado';

    final prettyJson = widget.alert.detalleTecnico == null
        ? null
        : const JsonEncoder.withIndent('  ').convert(widget.alert.detalleTecnico);

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
                  Icon(Icons.shield_outlined, color: severityColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detalle de alerta',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _KeyValue(label: 'Tipo', value: widget.alert.tipoIncumplimiento),
              const SizedBox(height: 8),
              _KeyValue(label: 'Empleado', value: employee),
              if ((widget.alert.empleadoCedula ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _KeyValue(label: 'Cédula', value: widget.alert.empleadoCedula!.trim()),
              ],
              if ((widget.branchName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _KeyValue(label: 'Sucursal', value: widget.branchName!.trim()),
              ],
              if (created != null) ...[
                const SizedBox(height: 8),
                _KeyValue(label: 'Creada', value: _fmt.format(created)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.10),
                        border: Border.all(color: severityColor.withValues(alpha: 0.22)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, color: severityColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Gravedad: ${widget.alert.gravedad?.value ?? 'advertencia'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: severityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.neutral100,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _status,
                    items: [
                      for (final s in AuditorAlertConstants.statuses)
                        DropdownMenuItem<String>(
                          value: s,
                          child: Text(AuditorAlertConstants.statusLabel(s)),
                        ),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _status = v ?? _status),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _justCtrl,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Justificación del auditor',
                  hintText: 'Describe el análisis y la decisión...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (prettyJson != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Detalle técnico (JSON)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Text(
                    prettyJson,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : widget.onOpenEmployeeAttendance,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Ver asistencia'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : widget.onOpenRecord,
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(widget.recordLabel ?? 'Ver evidencia'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final justification = _justCtrl.text.trim();
    if (_status == 'cerrada' && justification.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para cerrar una alerta, agrega una justificación.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        status: _status,
        justification: justification.isEmpty ? null : justification,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
      );
    }
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
          ),
        ),
      ],
    );
  }
}
