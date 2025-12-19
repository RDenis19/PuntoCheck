import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/auditor/widgets/audit/auditor_audit_detail_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/audit/auditor_audit_filters_sheet.dart';
import 'package:puntocheck/presentation/auditor/widgets/audit/auditor_audit_log_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/auditor_audit_providers.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AuditorAuditLogView extends ConsumerStatefulWidget {
  const AuditorAuditLogView({super.key});

  @override
  ConsumerState<AuditorAuditLogView> createState() => _AuditorAuditLogViewState();
}

class _AuditorAuditLogViewState extends ConsumerState<AuditorAuditLogView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(auditorBranchesProvider);
    final filter = ref.watch(auditorAuditLogFilterProvider);
    final logsAsync = ref.watch(auditorAuditLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Auditoría del sistema'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => _openFilters(context, ref, branchesAsync),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(auditorAuditLogProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchCtrl,
                builder: (context, value, _) {
                  final q = value.text.trim();
                  return TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por acción, tabla, actor o IP',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: q.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar',
                              onPressed: () => _searchCtrl.clear(),
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: EmptyState(
                    title: 'Error',
                    message: 'No se pudo cargar el log.\n$e',
                    icon: Icons.error_outline,
                    onAction: () => ref.invalidate(auditorAuditLogProvider),
                    actionLabel: 'Reintentar',
                  ),
                ),
                data: (logs) {
                  final q = _searchCtrl.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? logs
                      : logs.where((l) {
                          final hay = [
                            l.accion,
                            l.tablaAfectada,
                            l.idRegistroAfectado,
                            l.actorNombreCompleto,
                            l.actorCedula,
                            l.usuarioResponsableId,
                            l.ipOrigen,
                          ].whereType<String>().join(' ').toLowerCase();
                          return hay.contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyState(
                        title: 'Sin resultados',
                        message: 'No hay coincidencias con la búsqueda/filtros.',
                        icon: Icons.manage_search,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryRed,
                    onRefresh: () async => ref.refresh(auditorAuditLogProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = filtered[index];
                        return AuditorAuditLogCard(
                          log: log,
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AuditorAuditDetailSheet(log: log),
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
      ),
      bottomNavigationBar: _ActiveFiltersBar(
        filter: filter,
        onClear: () => ref.read(auditorAuditLogFilterProvider.notifier).state =
            AuditorAuditLogFilter.initial(),
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    WidgetRef ref,
    AsyncValue branchesAsync,
  ) async {
    final branches = branchesAsync.valueOrNull ?? const [];
    final initial = ref.read(auditorAuditLogFilterProvider);
    final next = await showModalBottomSheet<AuditorAuditLogFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuditorAuditFiltersSheet(initial: initial, branches: branches),
    );
    if (next == null) return;
    ref.read(auditorAuditLogFilterProvider.notifier).state = next;
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final AuditorAuditLogFilter filter;
  final VoidCallback onClear;

  const _ActiveFiltersBar({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final has = filter.dateRange != null ||
        filter.actionQuery.trim().isNotEmpty ||
        filter.table != null ||
        filter.actorId != null ||
        filter.branchId != null ||
        filter.actorRole != null;

    if (!has) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, color: AppColors.neutral700),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Filtros activos',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Restablecer'),
            ),
          ],
        ),
      ),
    );
  }
}
