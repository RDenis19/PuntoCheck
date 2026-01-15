
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:puntocheck/services/supabase_client.dart'; // Needed for signed url

class ManagerComplianceAlertsView extends ConsumerStatefulWidget {
  const ManagerComplianceAlertsView({super.key});

  @override
  ConsumerState<ManagerComplianceAlertsView> createState() =>
      _ManagerComplianceAlertsViewState();
}

class _ManagerComplianceAlertsViewState
    extends ConsumerState<ManagerComplianceAlertsView> {
  bool _pendingOnly = true;

  String? _employeeId;
  String? _severity; // leve | moderada | grave_legal

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(managerComplianceAlertsProvider(_pendingOnly));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de cumplimiento'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Filtros',
            icon: const Icon(Icons.filter_alt_rounded),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _HeaderFilters(
            pendingOnly: _pendingOnly,
            onChanged: (v) => setState(() => _pendingOnly = v),
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                title: 'Error cargando alertas',
                message: '$e',
                onRetry: () => ref.invalidate(
                  managerComplianceAlertsProvider(_pendingOnly),
                ),
              ),
              data: (alerts) {
                final filtered = _applyFilters(alerts);
                if (filtered.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.shield_rounded,
                    text: 'No hay alertas con estos filtros',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(
                    managerComplianceAlertsProvider(_pendingOnly),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final alert = filtered[index];
                      return _AlertCard(
                        alert: alert,
                        onTap: () => _openDetail(context, alert),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AlertasCumplimiento> _applyFilters(List<AlertasCumplimiento> alerts) {
    return alerts.where((a) {
      if (_severity != null && a.gravedad?.value != _severity) return false;


      if (_employeeId != null && a.empleadoId != _employeeId) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilters(BuildContext context) async {
    final teamAsync = await ref.read(managerTeamAllProvider(null).future);

    if (!context.mounted) return;

    final result = await showModalBottomSheet<_AlertFiltersResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _AlertFiltersSheet(
        team: teamAsync,
        selectedEmployeeId: _employeeId,
        selectedSeverity: _severity,
      ),
    );

    if (result == null) return;
    setState(() {

      _employeeId = result.employeeId;
      _severity = result.severity;
    });
  }

  Future<void> _openDetail(BuildContext context, AlertasCumplimiento alert) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _AlertDetailSheet(alert: alert),
    );
  }
}

class _HeaderFilters extends StatelessWidget {
  final bool pendingOnly;
  final ValueChanged<bool> onChanged;

  const _HeaderFilters({required this.pendingOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Pendientes')),
                ButtonSegment(value: false, label: Text('Todas')),
              ],
              selected: {pendingOnly},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertasCumplimiento alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(alert.gravedad?.value);
    final estado = alert.estado ?? 'pendiente';

    final title = _formatSnakeCase(alert.tipoIncumplimiento);
    final employee = alert.empleadoNombreCompleto;
    final desc =
        (alert.detalleTecnico?['descripcion'] as String?) ??
        (alert.detalleTecnico?['motivo'] as String?) ??
        'Detalle no disponible';
    final date = alert.fechaDeteccion;

    final dateStr = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: severityColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        text: alert.gravedad?.value ?? 'leve',
                        color: severityColor,
                      ),
                    ],
                  ),
                  if (employee != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      employee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SmallMeta(
                        icon: Icons.circle,
                        iconColor: estado == 'pendiente'
                            ? AppColors.warningOrange
                            : AppColors.successGreen,
                        text: 'Estado: $estado',
                      ),
                      if (dateStr != null) ...[
                        const SizedBox(width: 12),
                        _SmallMeta(
                          icon: Icons.calendar_today_rounded,
                          text: dateStr,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _severityColor(String? severity) {
    switch ((severity ?? '').toLowerCase()) {
      case 'grave_legal':
      case 'alta':
        return AppColors.errorRed;
      case 'moderada':
      case 'media':
        return AppColors.warningOrange;
      default:
        return AppColors.infoBlue;
    }
  }

  static String _formatSnakeCase(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _AlertDetailSheet extends ConsumerStatefulWidget {
  final AlertasCumplimiento alert;

  const _AlertDetailSheet({required this.alert});

  @override
  ConsumerState<_AlertDetailSheet> createState() => _AlertDetailSheetState();
}

class _AlertDetailSheetState extends ConsumerState<_AlertDetailSheet> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.alert.estado;
  }

  String _formatSnakeCase(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final severityColor = _AlertCard._severityColor(alert.gravedad?.value);



    final controllerState = ref.watch(managerComplianceAlertControllerProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.shield_rounded, color: severityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatSnakeCase(alert.tipoIncumplimiento),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (alert.empleadoNombreCompleto != null) ...[
              _KeyValueRow(
                label: 'Empleado',
                value: alert.empleadoNombreCompleto!,
              ),
              const SizedBox(height: 10),
            ],
            _KeyValueRow(
              label: 'Gravedad',
              value: _formatSnakeCase(alert.gravedad?.value ?? 'leve'),
            ),
            const SizedBox(height: 10),
            _KeyValueRow(
              label: 'Estado',
              value: _formatSnakeCase(alert.estado ?? 'pendiente'),
            ),
            const SizedBox(height: 14),
            if (alert.detalleTecnico != null) ...[
              const Text(
                'Detalle técnico',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     if (alert.detalleTecnico!['sucursal'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Sucursal: ${alert.detalleTecnico!['sucursal']}', style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
                        ),
                     if (alert.detalleTecnico!['descripcion'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Descripción: ${alert.detalleTecnico!['descripcion']}', style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
                        ),
                      if (alert.detalleTecnico!['motivo'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Motivo: ${alert.detalleTecnico!['motivo']}', style: const TextStyle(fontSize: 13, color: AppColors.neutral700)),
                        ),
                      // Fallback for other important fields we might want to see, or keep it clean as requested.
                      // Hiding raw IDs (registro_id) as per request for "bonito" UI.
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (alert.detalleTecnico != null && (alert.detalleTecnico!['evidencia_foto_url'] != null || alert.detalleTecnico!['documento_url'] != null)) ...[
                 _buildDocButton(context, alert.detalleTecnico!),
                 const SizedBox(height: 14),
            ],
            const Text(
              'Acción operativa',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Como manager puedes tomar acción (hablar con el empleado, ajustar turnos) y marcar el avance. '
              'La justificación legal normalmente la registra Auditor/Org Admin.',
              style: TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status ?? alert.estado,
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'en_revision', child: Text('En revisión')),
                      DropdownMenuItem(value: 'resuelta', child: Text('Resuelta')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Actualizar estado',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: controllerState.isLoading
                        ? null
                        : (v) => setState(() => _status = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: controllerState.isLoading
                    ? null
                    : () async {
                        final status = (_status ?? alert.estado) ?? 'pendiente';
                        try {
                          await ref
                              .read(
                                managerComplianceAlertControllerProvider.notifier,
                              )
                              .updateStatus(alertId: alert.id, status: status);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Estado actualizado'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
                child: controllerState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDocButton(BuildContext context, Map<String, dynamic> json) {
      final url = json['evidencia_foto_url'] ?? json['documento_url'];
      if (url == null || url is! String) return const SizedBox();

      return InkWell(
        onTap: () async {
          try {
             Uri uri;
             if (url.startsWith('http')) {
               uri = Uri.parse(url);
             } else {
               // Signed URL fallback
               final signed = await supabase.storage
                   .from('evidencias') 
                   .createSignedUrl(url, 60);
               uri = Uri.parse(signed);
             }
             if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo abrir el documento')),
                   );
                 }
             }
          } catch(e) {
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
               );
             }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
             color: AppColors.infoBlue.withValues(alpha: 0.1),
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.attachment_rounded, size: 16, color: AppColors.infoBlue),
               SizedBox(width: 8),
               Text('Ver evidencia/documento', style: TextStyle(color: AppColors.infoBlue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
  }
}

class _AlertFiltersSheet extends StatefulWidget {
  final List<Perfiles> team;
  final String? selectedEmployeeId;
  final String? selectedSeverity;

  const _AlertFiltersSheet({
    required this.team,
    required this.selectedEmployeeId,
    required this.selectedSeverity,
  });

  @override
  State<_AlertFiltersSheet> createState() => _AlertFiltersSheetState();
}

class _AlertFiltersSheetState extends State<_AlertFiltersSheet> {
  String? _employeeId;
  String? _severity;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.selectedEmployeeId;
    _severity = widget.selectedSeverity;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _employeeId = null;
                    _severity = null;
                  }),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _employeeId,
              decoration: const InputDecoration(
                labelText: 'Empleado',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...widget.team.map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.nombres} ${p.apellidos}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _employeeId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Gravedad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas')),
                DropdownMenuItem(value: 'leve', child: Text('Leve')),
                DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
                DropdownMenuItem(value: 'grave_legal', child: Text('Grave legal')),
              ],
              onChanged: (v) => setState(() => _severity = v),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    _AlertFiltersResult(
                      branchId: null, 
                      employeeId: _employeeId,
                      severity: _severity,
                    ),
                  );
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertFiltersResult {
  final String? branchId;
  final String? employeeId;
  final String? severity;

  const _AlertFiltersResult({
    required this.branchId,
    required this.employeeId,
    required this.severity,
  });
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _SmallMeta({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? AppColors.neutral600),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.neutral900),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: AppColors.neutral300),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: AppColors.errorRed),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral600),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
