import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/auditor/widgets/attendance/auditor_attendance_filters_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/attendance/auditor_attendance_record_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAttendanceView extends ConsumerStatefulWidget {
  const AuditorAttendanceView({super.key});

  @override
  ConsumerState<AuditorAttendanceView> createState() =>
      _AuditorAttendanceViewState();
}

class _AuditorAttendanceViewState extends ConsumerState<AuditorAttendanceView> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(auditorAttendanceFilterProvider);
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
      final current = ref.read(auditorAttendanceFilterProvider);
      final next = current.copyWith(query: _searchCtrl.text);
      if (next == current) return;
      ref.read(auditorAttendanceFilterProvider.notifier).state = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(auditorBranchesProvider);
    final filter = ref.watch(auditorAttendanceFilterProvider);
    final listAsync = ref.watch(auditorAttendanceProvider);

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
                // Spacer para balancear el título centrado
                const SizedBox(width: 96), 
                const Expanded(
                  child: Center(
                    child: Text(
                      'Asistencia',
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
                        onPressed: () => ref.invalidate(auditorAttendanceProvider),
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
                    hintText: 'Buscar por empleado (nombre o cédula)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(auditorAttendanceFilterProvider.notifier)
                                  .state = filter.copyWith(query: '');
                            },
                            icon: const Icon(Icons.close_rounded),
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
              ref.read(auditorAttendanceFilterProvider.notifier).state =
                  AuditorAttendanceFilter.initial().copyWith(query: filter.query);
            },
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (e, _) => _ErrorState(
                message: 'No se pudo cargar la asistencia.\n$e',
                onRetry: () => ref.invalidate(auditorAttendanceProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyState(
                      title: 'Sin resultados',
                      message:
                          'Prueba ajustando fechas, sucursal o el texto de búsqueda.',
                      icon: Icons.manage_search_rounded,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () async =>
                      ref.refresh(auditorAttendanceProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return AuditorAttendanceRecordCard(
                        entry: entry,
                        onTap: () => context.push(
                          '${AppRoutes.auditorHome}/asistencia/${entry.record.id}',
                        ),
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

  Future<void> _openFilters(
    BuildContext context,
    AsyncValue branchesAsync,
  ) async {
    final branches = branchesAsync.valueOrNull ?? const [];
    final initial = ref.read(auditorAttendanceFilterProvider);

    final next = await showModalBottomSheet<AuditorAttendanceFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditorAttendanceFiltersSheet(
        initial: initial,
        branches: branches,
      ),
    );

    if (!mounted || next == null) return;
    ref.read(auditorAttendanceFilterProvider.notifier).state =
        next.copyWith(query: initial.query);
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final AuditorAttendanceFilter filter;
  final AsyncValue branchesAsync;
  final VoidCallback onClear;

  const _ActiveFiltersBar({
    required this.filter,
    required this.branchesAsync,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    String? branchLabel;
    final branches = branchesAsync.valueOrNull;
    if (filter.branchId != null && branches != null) {
      final match = branches.where((b) => b.id == filter.branchId);
      if (match.isNotEmpty) {
        branchLabel = match.first.nombre;
      }
    }

    final range = filter.dateRange;
    final rangeLabel = range == null
        ? null
        : '${range.start.day.toString().padLeft(2, '0')}/'
            '${range.start.month.toString().padLeft(2, '0')} - '
            '${range.end.day.toString().padLeft(2, '0')}/'
            '${range.end.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (rangeLabel != null)
                  _Chip(label: rangeLabel, icon: Icons.date_range_rounded),
                if (branchLabel != null)
                  _Chip(label: branchLabel, icon: Icons.store_rounded),
                if (filter.onlyGeofenceIssues)
                  const _Chip(
                    label: 'Fuera de geocerca',
                    icon: Icons.location_off_rounded,
                  ),
                if (filter.onlyMockLocation)
                  const _Chip(label: 'Mock location', icon: Icons.gps_off_rounded),
              ],
            ),
          ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: EmptyState(
        title: 'Error',
        message: message,
        icon: Icons.error_outline_rounded,
        onAction: onRetry,
        actionLabel: 'Reintentar',
      ),
    );
  }
}
