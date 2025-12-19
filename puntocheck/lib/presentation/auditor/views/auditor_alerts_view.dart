import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_stat_card.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_card.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_constants.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_detail_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_filters_sheet.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAlertsView extends ConsumerStatefulWidget {
  const AuditorAlertsView({super.key});

  @override
  ConsumerState<AuditorAlertsView> createState() => _AuditorAlertsViewState();
}

class _AuditorAlertsViewState extends ConsumerState<AuditorAlertsView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(auditorAlertsFilterProvider);
    _searchCtrl.text = filter.query;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final current = ref.read(auditorAlertsFilterProvider);
      final next = current.copyWith(query: _searchCtrl.text);
      if (next == current) return;
      ref.read(auditorAlertsFilterProvider.notifier).state = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(auditorBranchesProvider);
    final filter = ref.watch(auditorAlertsFilterProvider);
    final alertsAsync = ref.watch(auditorAlertsProvider);

    ref.listen(auditorAlertsControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta actualizada')),
        ),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        ),
      );
    });

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alertas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neutral900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Filtros',
                  onPressed: () => _openFilters(context, branchesAsync),
                  icon: const Icon(Icons.tune),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: () => ref.invalidate(auditorAlertsProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (context, value, _) {
                final text = value.text.trim();
                return TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por empleado o cédula',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(auditorAlertsFilterProvider.notifier)
                                  .state = filter.copyWith(query: '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),
          _ActiveFiltersBar(
            filter: filter,
            branchesAsync: branchesAsync,
            onClear: () {
              ref.read(auditorAlertsFilterProvider.notifier).state =
                  AuditorAlertsFilter.initial().copyWith(query: filter.query);
            },
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  title: 'Error',
                  message: 'No se pudieron cargar las alertas.\n$e',
                  icon: Icons.error_outline,
                  onAction: () => ref.invalidate(auditorAlertsProvider),
                  actionLabel: 'Reintentar',
                ),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyState(
                      title: 'Sin alertas',
                      message: 'No hay alertas con los filtros actuales.',
                      icon: Icons.shield_outlined,
                    ),
                  );
                }

                final summary = _AlertsSummary.from(alerts);
                final branches = branchesAsync.valueOrNull ?? const [];
                String? branchNameFor(String? id) {
                  if (id == null) return null;
                  for (final b in branches) {
                    if (b.id == id) return b.nombre;
                  }
                  return null;
                }

                    return RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () async => ref.refresh(auditorAlertsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AdminStatCard(
                              label: 'Pendientes',
                              value: '${summary.pending}',
                              hint: 'Por revisar',
                              icon: Icons.flag_outlined,
                              color: AppColors.warningOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdminStatCard(
                              label: 'En revisión',
                              value: '${summary.inReview}',
                              hint: 'Abiertas',
                              icon: Icons.manage_search_outlined,
                              color: AppColors.infoBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AdminStatCard(
                              label: 'Cerradas',
                              value: '${summary.closed}',
                              hint: 'Resueltas',
                              icon: Icons.verified_outlined,
                              color: AppColors.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AdminStatCard(
                              label: 'Total',
                              value: '${summary.total}',
                              hint: 'Cargadas',
                              icon: Icons.shield_outlined,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: 'Métricas rápidas',
                        child: _QuickMetrics(
                          alerts: alerts,
                          branchNameFor: branchNameFor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Centro de control',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final a in alerts) ...[
                        AuditorAlertCard(
                          alert: a,
                          branchName: branchNameFor(a.empleadoSucursalId),
                          onTap: () => _openAlertDetail(
                            context,
                            a,
                            branchNameFor(a.empleadoSucursalId),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, AsyncValue branchesAsync) async {
    final branches = branchesAsync.valueOrNull ?? const [];
    final initial = ref.read(auditorAlertsFilterProvider);

    final next = await showModalBottomSheet<AuditorAlertsFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditorAlertFiltersSheet(initial: initial, branches: branches),
    );

    if (!mounted || next == null) return;
    ref.read(auditorAlertsFilterProvider.notifier).state =
        next.copyWith(query: initial.query);
  }

  Future<void> _openAlertDetail(
    BuildContext context,
    AlertasCumplimiento alert,
    String? branchName,
  ) async {
    final recordId = _tryExtractAttendanceRecordId(alert.detalleTecnico);
    final controller = ref.read(auditorAlertsControllerProvider.notifier);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditorAlertDetailSheet(
        alert: alert,
        branchName: branchName,
        recordLabel: recordId == null ? 'Ver evidencia' : 'Ir a marca',
        onOpenRecord: recordId == null
            ? null
            : () {
                Navigator.pop(context);
                context.push('${AppRoutes.auditorHome}/asistencia/$recordId');
              },
        onOpenEmployeeAttendance: alert.empleadoId == null
            ? null
            : () {
                final q = (alert.empleadoCedula ?? '').trim().isNotEmpty
                    ? alert.empleadoCedula!.trim()
                    : (alert.empleadoNombreCompleto ?? '').trim();
                ref.read(auditorAttendanceFilterProvider.notifier).state =
                    AuditorAttendanceFilter.initial().copyWith(
                      query: q,
                      branchId: alert.empleadoSucursalId,
                    );
                ref.read(auditorTabIndexProvider.notifier).state = 1;
                Navigator.pop(context);
                context.go(AppRoutes.auditorHome);
              },
        onSave: ({required status, required justification}) => controller.resolve(
          alertId: alert.id,
          newStatus: status,
          justification: justification,
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final AuditorAlertsFilter filter;
  final AsyncValue branchesAsync;
  final VoidCallback onClear;

  const _ActiveFiltersBar({
    required this.filter,
    required this.branchesAsync,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final branches = branchesAsync.valueOrNull ?? const [];
    String? branchLabel;
    if (filter.branchId != null) {
      for (final b in branches) {
        if (b.id == filter.branchId) branchLabel = b.nombre;
      }
    }

    final chips = <Widget>[
      if (filter.status != null)
        _Chip(
          label: 'Estado: ${AuditorAlertConstants.statusLabel(filter.status)}',
          icon: Icons.flag_outlined,
        ),
      if (branchLabel != null) _Chip(label: branchLabel, icon: Icons.store_outlined),
      if (filter.severity != null)
        _Chip(label: filter.severity!.value, icon: Icons.priority_high),
      if ((filter.typeQuery ?? '').trim().isNotEmpty)
        _Chip(label: filter.typeQuery!.trim(), icon: Icons.category_outlined),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.neutral700),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSummary {
  final int total;
  final int pending;
  final int inReview;
  final int closed;

  const _AlertsSummary({
    required this.total,
    required this.pending,
    required this.inReview,
    required this.closed,
  });

  factory _AlertsSummary.from(List<AlertasCumplimiento> alerts) {
    var pending = 0;
    var inReview = 0;
    var closed = 0;
    for (final a in alerts) {
      switch ((a.estado ?? '').trim()) {
        case 'pendiente':
          pending += 1;
          break;
        case 'en_revision':
          inReview += 1;
          break;
        case 'cerrada':
          closed += 1;
          break;
      }
    }
    return _AlertsSummary(
      total: alerts.length,
      pending: pending,
      inReview: inReview,
      closed: closed,
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  final List<AlertasCumplimiento> alerts;
  final String? Function(String? branchId) branchNameFor;

  const _QuickMetrics({
    required this.alerts,
    required this.branchNameFor,
  });

  @override
  Widget build(BuildContext context) {
    final byType = <String, int>{};
    final byBranch = <String, int>{};
    final byEmployee = <String, int>{};

    for (final a in alerts) {
      final t = a.tipoIncumplimiento.trim();
      if (t.isNotEmpty) byType[t] = (byType[t] ?? 0) + 1;

      final branchId = a.empleadoSucursalId;
      if (branchId != null && branchId.isNotEmpty) {
        byBranch[branchId] = (byBranch[branchId] ?? 0) + 1;
      }

      final employee = (a.empleadoNombreCompleto ?? '').trim();
      if (employee.isNotEmpty) byEmployee[employee] = (byEmployee[employee] ?? 0) + 1;
    }

    List<MapEntry<String, int>> top(Map<String, int> input) {
      final list = input.entries.toList();
      list.sort((a, b) => b.value.compareTo(a.value));
      return list.take(3).toList();
    }

    final topTypes = top(byType);
    final topEmployees = top(byEmployee);
    final topBranches = top(byBranch)
        .map((e) => MapEntry(branchNameFor(e.key) ?? e.key.substring(0, 8), e.value))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricRow(
          title: 'Por tipo',
          items: [
            for (final e in topTypes) _MetricChip(label: e.key, value: e.value),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          title: 'Por sucursal',
          items: [
            for (final e in topBranches)
              _MetricChip(label: e.key, value: e.value),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          title: 'Por empleado',
          items: [
            for (final e in topEmployees) _MetricChip(label: e.key, value: e.value),
          ],
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MetricRow({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral700,
              ),
            ),
          ),
          const Expanded(
            child: Text('—', style: TextStyle(color: AppColors.neutral600)),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Text(
        '$label · $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.neutral700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String? _tryExtractAttendanceRecordId(Map<String, dynamic>? json) {
  if (json == null) return null;
  const candidates = [
    'registro_asistencia_id',
    'registro_id',
    'registros_asistencia_id',
    'attendance_id',
  ];

  bool looksLikeUuid(String s) {
    final t = s.trim();
    final uuid =
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuid.hasMatch(t);
  }

  for (final key in candidates) {
    final v = json[key];
    if (v is String && looksLikeUuid(v)) return v.trim();
  }

  // Búsqueda superficial: si hay un valor string UUID en el primer nivel, lo usamos.
  for (final v in json.values) {
    if (v is String && looksLikeUuid(v)) return v.trim();
  }

  return null;
}
