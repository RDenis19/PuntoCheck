import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_card.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_constants.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_detail_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/alerts/auditor_alert_filters_sheet.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
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
        data: (_) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alerta actualizada'))),
        error: (e, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'))),
      );
    });

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Spacer para balancear
                const SizedBox(width: 96),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Alertas de Cumplimiento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Filtros',
                        onPressed: () => _openFilters(context, branchesAsync),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: () => ref.invalidate(auditorAlertsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
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
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(auditorAlertsFilterProvider.notifier)
                                  .state = filter.copyWith(
                                query: '',
                              );
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.neutral300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                  icon: Icons.error_outline_rounded,
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
                      icon: Icons.shield_rounded,
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

                final sortedAlerts = List<AlertasCumplimiento>.from(alerts);
                sortedAlerts.sort((a, b) {
                  final da = a.fechaDeteccion ?? DateTime(2000);
                  final db = b.fechaDeteccion ?? DateTime(2000);
                  return db.compareTo(da); // Descending
                });

                // Grouping logic
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));

                final todayAlerts = <AlertasCumplimiento>[];
                final yesterdayAlerts = <AlertasCumplimiento>[];
                final olderAlerts = <AlertasCumplimiento>[];

                for (final a in sortedAlerts) {
                  final d = a.fechaDeteccion;
                  if (d == null) {
                    olderAlerts.add(a);
                    continue;
                  }
                  final date = DateTime(d.year, d.month, d.day);
                  if (date.isAtSameMomentAs(today)) {
                    todayAlerts.add(a);
                  } else if (date.isAtSameMomentAs(yesterday)) {
                    yesterdayAlerts.add(a);
                  } else {
                    olderAlerts.add(a);
                  }
                }

                Widget buildSectionHeader(String title, IconData icon) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: AppColors.neutral500),
                        const SizedBox(width: 8),
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () async =>
                      ref.refresh(auditorAlertsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    children: [
                      // Resumen Rojo tipo Header
                      _SummaryHeader(summary: summary),

                      if (todayAlerts.isNotEmpty) ...[
                        buildSectionHeader('Hoy', Icons.today_rounded),
                        for (final a in todayAlerts) ...[
                          AuditorAlertCard(
                            alert: a,
                            branchName: branchNameFor(a.empleadoSucursalId),
                            isNew: true,
                            onTap: () => _openAlertDetail(
                              context,
                              a,
                              branchNameFor(a.empleadoSucursalId),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],

                      if (yesterdayAlerts.isNotEmpty) ...[
                        buildSectionHeader('Ayer', Icons.history_rounded),
                        for (final a in yesterdayAlerts) ...[
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

                      if (olderAlerts.isNotEmpty) ...[
                        buildSectionHeader('Historial', Icons.archive_outlined),
                        for (final a in olderAlerts) ...[
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

                      const SizedBox(height: 24),
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

  Future<void> _openFilters(
    BuildContext context,
    AsyncValue branchesAsync,
  ) async {
    final branches = branchesAsync.valueOrNull ?? const [];
    final initial = ref.read(auditorAlertsFilterProvider);

    final next = await showModalBottomSheet<AuditorAlertsFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AuditorAlertFiltersSheet(initial: initial, branches: branches),
    );

    if (!mounted || next == null) return;
    ref.read(auditorAlertsFilterProvider.notifier).state = next.copyWith(
      query: initial.query,
    );
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
                ref
                    .read(auditorAttendanceFilterProvider.notifier)
                    .state = AuditorAttendanceFilter.initial().copyWith(
                  query: q,
                  branchId: alert.empleadoSucursalId,
                );
                ref.read(auditorTabIndexProvider.notifier).state = 1;
                Navigator.pop(context);
                context.go(AppRoutes.auditorHome);
              },
        onSave: ({required status, required justification}) =>
            controller.resolve(
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
          icon: Icons.flag_rounded,
        ),
      if (branchLabel != null)
        _Chip(label: branchLabel, icon: Icons.store_rounded),
      if (filter.severity != null)
        _Chip(label: filter.severity!.value, icon: Icons.priority_high_rounded),
      if ((filter.typeQuery ?? '').trim().isNotEmpty)
        _Chip(label: filter.typeQuery!.trim(), icon: Icons.category_rounded),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(child: Wrap(spacing: 8, runSpacing: 8, children: chips)),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded),
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
  final int newToday;

  const _AlertsSummary({
    required this.total,
    required this.pending,
    required this.inReview,
    required this.closed,
    required this.newToday,
  });

  factory _AlertsSummary.from(List<AlertasCumplimiento> alerts) {
    var pending = 0;
    var inReview = 0;
    var closed = 0;
    var newToday = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final a in alerts) {
      if ((a.estado ?? '').trim() == 'pendiente') {
        pending += 1;
      } else if ((a.estado ?? '').trim() == 'en_revision') {
        inReview += 1;
      } else if ((a.estado ?? '').trim() == 'cerrada') {
        closed += 1;
      }

      if (a.fechaDeteccion != null) {
        final d = a.fechaDeteccion!;
        final date = DateTime(d.year, d.month, d.day);
        if (date.isAtSameMomentAs(today)) {
          newToday += 1;
        }
      }
    }
    return _AlertsSummary(
      total: alerts.length,
      pending: pending,
      inReview: inReview,
      closed: closed,
      newToday: newToday,
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final _AlertsSummary summary;
  const _SummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: 'Nuevas Hoy', value: '${summary.newToday}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _StatItem(label: 'Pendientes', value: '${summary.pending}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _StatItem(label: 'En Revisión', value: '${summary.inReview}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
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
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
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
