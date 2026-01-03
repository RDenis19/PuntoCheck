import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/presentation/admin/widgets/hours_bank_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeHoursBankView extends ConsumerStatefulWidget {
  const EmployeeHoursBankView({super.key});

  @override
  ConsumerState<EmployeeHoursBankView> createState() => _EmployeeHoursBankViewState();
}

class _EmployeeHoursBankViewState extends ConsumerState<EmployeeHoursBankView> {
  final _searchCtrl = TextEditingController();
  _HoursBankScope _scope = _HoursBankScope.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankAsync = ref.watch(employeeHoursBankProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Banco de horas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(employeeHoursBankProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: bankAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (e, _) => _ErrorView(
            message: 'No se pudo cargar tu banco de horas.\n$e',
            onRetry: () => ref.invalidate(employeeHoursBankProvider),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const EmptyState(
                icon: Icons.access_time_rounded,
                title: 'Sin movimientos',
                message: 'Aquí verás tus horas acumuladas o usadas cuando sean aprobadas.',
              );
            }

            final filtered = _applyFilters(records);
            if (filtered.isEmpty) {
              return _NoResultsView(
                onClear: () => setState(() {
                  _scope = _HoursBankScope.all;
                  _searchCtrl.clear();
                }),
              );
            }

            final totalHours = filtered.fold<double>(
              0,
              (sum, r) => sum + r.cantidadHoras,
            );

            return RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () async => ref.refresh(employeeHoursBankProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _SummaryCard(totalHours: totalHours, recordCount: filtered.length),
                  const SizedBox(height: 12),
                  _FilterBar(
                    scope: _scope,
                    onScopeChanged: (s) => setState(() => _scope = s),
                    searchCtrl: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() => _searchCtrl.clear()),
                  ),
                  const SizedBox(height: 12),
                  ...filtered.map(
                    (r) => HoursBankCard(
                      record: r,
                      employeeName: 'Tú',
                      onTap: () => _openDetail(context, r),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<BancoHorasCompensatorias> _applyFilters(List<BancoHorasCompensatorias> input) {
    final now = DateTime.now();
    final query = _searchCtrl.text.trim().toLowerCase();

    Iterable<BancoHorasCompensatorias> out = input;
    if (_scope != _HoursBankScope.all) {
      out = out.where((r) {
        final dt = r.creadoEn;
        if (dt == null) return false;
        switch (_scope) {
          case _HoursBankScope.thisMonth:
            return dt.year == now.year && dt.month == now.month;
          case _HoursBankScope.thisYear:
            return dt.year == now.year;
          case _HoursBankScope.all:
            return true;
        }
      });
    }

    if (query.isNotEmpty) {
      out = out.where((r) => r.concepto.toLowerCase().contains(query));
    }

    return out.toList();
  }

  void _openDetail(BuildContext context, BancoHorasCompensatorias record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HoursBankDetailSheet(record: record),
    );
  }
}

enum _HoursBankScope { all, thisMonth, thisYear }

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.scope,
    required this.onScopeChanged,
    required this.searchCtrl,
    required this.onChanged,
    required this.onClear,
  });

  final _HoursBankScope scope;
  final ValueChanged<_HoursBankScope> onScopeChanged;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ScopeChip(
                  selected: scope == _HoursBankScope.all,
                  label: 'Todos',
                  onTap: () => onScopeChanged(_HoursBankScope.all),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScopeChip(
                  selected: scope == _HoursBankScope.thisMonth,
                  label: 'Este mes',
                  onTap: () => onScopeChanged(_HoursBankScope.thisMonth),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScopeChip(
                  selected: scope == _HoursBankScope.thisYear,
                  label: 'Este año',
                  onTap: () => onScopeChanged(_HoursBankScope.thisYear),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchCtrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchCtrl.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              hintText: 'Buscar por concepto...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primaryRed : AppColors.neutral100;
    final fg = selected ? Colors.white : AppColors.neutral700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryRed : AppColors.neutral200,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 12),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalHours, required this.recordCount});

  final double totalHours;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    final isPositive = totalHours >= 0;
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sign${totalHours.toStringAsFixed(1)} h',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$recordCount movimientos',
                  style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursBankDetailSheet extends StatelessWidget {
  const _HoursBankDetailSheet({required this.record});

  final BancoHorasCompensatorias record;

  @override
  Widget build(BuildContext context) {
    final isPositive = record.cantidadHoras > 0;
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final created = record.creadoEn;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Detalle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPositive ? Icons.add_rounded : Icons.remove_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.concepto,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            created != null ? fmt.format(created) : '—',
                            style: const TextStyle(color: AppColors.neutral700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${record.cantidadHoras.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Aprobado por',
                value: (record.aprobadoPorId ?? '').trim().isEmpty
                    ? '—'
                    : _shortId(record.aprobadoPorId!),
              ),
              _DetailRow(
                label: 'Renuncia pago',
                value: record.aceptaRenunciaPago == true ? 'Sí' : 'No',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.neutral900),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.onClear});
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
                'No hay movimientos para los filtros seleccionados.',
                style: TextStyle(color: AppColors.neutral700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
                  icon: const Icon(Icons.refresh_rounded),
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

