import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/presentation/admin/widgets/hours_bank_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de banco de horas del equipo del Manager.
/// 
/// Permite al manager:
/// - Ver movimientos de horas del equipo
/// - Filtrar por empleado
/// - Ver detalles (horas, concepto, aprobador)
/// 
/// Reutiliza `HoursBankCard` del Admin (sin duplicar código).
class ManagerHoursBankView extends ConsumerStatefulWidget {
  const ManagerHoursBankView({super.key});

  @override
  ConsumerState<ManagerHoursBankView> createState() =>
      _ManagerHoursBankViewState();
}

class _ManagerHoursBankViewState extends ConsumerState<ManagerHoursBankView> {
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final hoursBankAsync =
        ref.watch(managerTeamHoursBankProvider(_selectedEmployeeId));
    final teamAsync = ref.watch(managerTeamProvider(null)); // null = todo el equipo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Horas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(managerTeamHoursBankProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por empleado
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por empleado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 8),
                teamAsync.when(
                  data: (team) => DropdownButtonFormField<String?>(
                    value: _selectedEmployeeId,
                    decoration: InputDecoration(
                      hintText: 'Todos los empleados',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.neutral300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.neutral300),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los empleados'),
                      ),
                      ...team.map(
                        (employee) => DropdownMenuItem<String?>(
                          value: employee.id,
                          child: Text(employee.nombreCompleto),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEmployeeId = value;
                      });
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Text('Error cargando equipo'),
                ),
              ],
            ),
          ),

          // Lista de movimientos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(managerTeamHoursBankProvider);
              },
              color: AppColors.primaryRed,
              child: hoursBankAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return EmptyState(
                      icon: Icons.access_time_rounded,
                      title: 'Sin movimientos',
                      message: _selectedEmployeeId != null
                          ? 'Este empleado no tiene movimientos de horas'
                          : 'No hay movimientos de horas registrados',
                    );
                  }

                  // Calcular balance total
                  final totalHours = records.fold<double>(
                    0.0,
                    (sum, record) => sum + record.cantidadHoras,
                  );

                  return Column(
                    children: [
                      // Card de resumen
                      _SummaryCard(
                        totalHours: totalHours,
                        recordCount: records.length,
                      ),

                      // Lista de registros
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            
                            // Obtener nombre del empleado
                            final employeeProfile = ref
                                .watch(managerPersonProvider(record.empleadoId))
                                .valueOrNull;

                            final employeeName = employeeProfile != null
                                ? employeeProfile.nombreCompleto
                                : 'Cargando...';

                            // Reutilizar HoursBankCard del Admin
                            return HoursBankCard(
                              record: record,
                              employeeName: employeeName,
                              onTap: () {
                                // TODO: Mostrar detalle si es necesario
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Movimiento: ${record.concepto}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryRed,
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error cargando banco de horas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.neutral700),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.invalidate(managerTeamHoursBankProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Card de resumen
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final double totalHours;
  final int recordCount;

  const _SummaryCard({
    required this.totalHours,
    required this.recordCount,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = totalHours >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  AppColors.successGreen,
                  AppColors.successGreen.withValues(alpha: 0.85),
                ]
              : [
                  AppColors.errorRed,
                  AppColors.errorRed.withValues(alpha: 0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.successGreen : AppColors.errorRed)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                '${isPositive ? '+' : ''}${totalHours.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'horas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$recordCount ${recordCount == 1 ? 'movimiento' : 'movimientos'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
