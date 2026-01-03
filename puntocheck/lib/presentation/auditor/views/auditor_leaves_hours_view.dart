import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/admin/widgets/request_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/auditor_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';

class AuditorLeavesHoursView extends StatelessWidget {
  const AuditorLeavesHoursView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: TabBarView(
                children: [
                   _LeavesTab(),
                   _HoursBankTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Center(
              child: Text(
                'Permisos y Banco de Horas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          const TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.neutral600,
            indicatorColor: AppColors.primaryRed,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Solicitudes Permisos'),
              Tab(text: 'Banco de Horas'),
            ],
          ),
          const Divider(height: 1, color: AppColors.neutral200),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// TAB 1: PERMISOS
// ----------------------------------------------------------------------------
class _LeavesTab extends ConsumerWidget {
  const _LeavesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(auditorLeavesProvider);
    final filter = ref.watch(auditorLeavesFilterProvider);

    return Column(
      children: [
        // Filtros
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Buscador
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar empleado...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.neutral300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) {
                    ref.read(auditorLeavesFilterProvider.notifier).state =
                        filter.copyWith(query: val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Dropdown Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: DropdownButton<EstadoAprobacion?>(
                  value: filter.status,
                  underline: const SizedBox(),
                  hint: const Text('Estado'),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.neutral500),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                     ...EstadoAprobacion.values.map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(auditorLeavesFilterProvider.notifier).state =
                        filter.copyWith(status: val, statusToNull: val == null);
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Lista
        Expanded(
          child: leavesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
            data: (requests) {
              if (requests.isEmpty) {
                return const EmptyState(
                  title: 'Sin solicitudes',
                  message: 'No se encontraron permisos con estos filtros.',
                  icon: Icons.event_busy_rounded,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return RequestCard(
                    request: requests[index],
                    // Auditor solo ve, no edita por ahora. O podría ver detalle.
                    onTap: () {},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// TAB 2: BANCO DE HORAS
// ----------------------------------------------------------------------------
class _HoursBankTab extends ConsumerWidget {
  const _HoursBankTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(auditorHoursBankProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
             decoration: InputDecoration(
              hintText: 'Buscar empleado por nombre o cédula...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.neutral300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              ref.read(auditorHoursBankFilterProvider.notifier).state =
                  AuditorHoursBankFilter(query: val);
            },
          ),
        ),
        Expanded(
          child: hoursAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
            data: (entries) {
              if (entries.isEmpty) {
                return const EmptyState(
                  title: 'Sin registros',
                  message: 'No hay movimientos en el banco de horas.',
                  icon: Icons.hourglass_empty_rounded,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _HoursBankCard(entries[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HoursBankCard extends StatelessWidget {
  final BancoHorasCompensatorias entry;
  const _HoursBankCard(this.entry);

  @override
  Widget build(BuildContext context) {
    final dateStr = entry.creadoEn != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(entry.creadoEn!)
        : '-';
    final horas = entry.cantidadHoras;
    final isPositive = horas >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono circular
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.successGreen.withValues(alpha: 0.1)
                  : AppColors.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
              color: isPositive ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 14),
          // Info Central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.empleadoNombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.neutral900,
                  ),
                ),
                Text(
                  entry.concepto,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ),
          // Cantidad horas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${horas.toStringAsFixed(1)} h',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                ),
              ),
              if (entry.aceptaRenunciaPago == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Renuncia Pago', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

