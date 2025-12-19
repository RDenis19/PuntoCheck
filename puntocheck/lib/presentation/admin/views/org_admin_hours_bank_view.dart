import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_hours_entry_view.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/hours_bank_card.dart';
import 'package:puntocheck/presentation/admin/widgets/hours_bank_stats.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/hours_bank_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Provider para banco de horas
final _hoursBankProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null) throw Exception('No org ID');
  return HoursBankService.instance.getHoursBankRecords(orgId);
});

/// Vista principal del banco de horas compensatorias
class OrgAdminHoursBankView extends ConsumerWidget {
  const OrgAdminHoursBankView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursBankAsync = ref.watch(_hoursBankProvider);

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
              ref.invalidate(_hoursBankProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_hoursBankProvider);
            await ref.read(_hoursBankProvider.future);
          },
          child: hoursBankAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return EmptyState(
                  icon: Icons.access_time_outlined,
                  title: 'Sin registros',
                  subtitle: 'Aún no hay horas registradas en el banco',
                  primaryLabel: 'Agregar Registro',
                  onPrimary: () => _navigateToNew(context),
                );
              }

              // Calcular stats
              double totalHours = 0;
              for (final record in records) {
                totalHours += record.cantidadHoras;
              }

              return CustomScrollView(
                slivers: [
                  // Estadísticas
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: HoursBankStats(
                        totalHours: totalHours,
                        totalRecords: records.length,
                      ),
                    ),
                  ),

                  // Header lista
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'Historial de Registros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                  ),

                  // Lista
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final record = records[index];
                        final employeeProfile = ref
                            .watch(orgAdminPersonProvider(record.empleadoId))
                            .valueOrNull;
                        final employeeName =
                            employeeProfile?.nombreCompleto ?? 'Cargando...';
                        return HoursBankCard(
                          record: record,
                          employeeName: employeeName,
                          onTap: () {
                            // TODO: Ver detalle
                          },
                        );
                      }, childCount: records.length),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
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
                      onPressed: () => ref.invalidate(_hoursBankProvider),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNew(context),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Registro'),
      ),
    );
  }

  void _navigateToNew(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrgAdminNewHoursEntryView()),
    );
  }
}
