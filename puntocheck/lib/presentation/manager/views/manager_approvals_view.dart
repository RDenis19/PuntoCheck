import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/admin/widgets/leave_filter_chip.dart';
import 'package:puntocheck/presentation/admin/widgets/leave_stat_card.dart';
import 'package:puntocheck/presentation/admin/widgets/request_card.dart';
import 'package:puntocheck/presentation/manager/views/manager_leave_detail_view.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista para revisar y resolver solicitudes de permisos del equipo del Manager.
/// Refactorizada para coincidir con la UI del Admin (OrgAdminLeavesAndHoursView).
class ManagerApprovalsView extends ConsumerStatefulWidget {
  const ManagerApprovalsView({super.key});

  @override
  ConsumerState<ManagerApprovalsView> createState() =>
      _ManagerApprovalsViewState();
}

class _ManagerApprovalsViewState extends ConsumerState<ManagerApprovalsView> {
  EstadoAprobacion? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    // Fetch TODAS las solicitudes del equipo (pendingOnly = false)
    final permissionsAsync = ref.watch(
      managerTeamPermissionsProvider(false),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos y Vacaciones'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(managerTeamPermissionsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(managerTeamPermissionsProvider),
        color: AppColors.primaryRed,
        child: permissionsAsync.when(
          data: (allPermissions) {
            // Filtrar localmente según el filtro seleccionado
            final permissions = _selectedFilter == null
                ? allPermissions
                : allPermissions
                    .where((r) => r.estado == _selectedFilter)
                    .toList();

            // Calcular estadísticas de TODAS las solicitudes
            final stats = _calculateStats(allPermissions);

            return CustomScrollView(
              slivers: [
                // Header con estadísticas
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Resumen'.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutral500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: LeaveStatCard(
                                  label: 'Pendientes',
                                  value: stats['pendientes'].toString(),
                                  icon: Icons.pending_rounded,
                                  color: AppColors.warningOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 200,
                                child: LeaveStatCard(
                                  label: 'Aprobados',
                                  value: stats['aprobados'].toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  color: AppColors.successGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 200,
                                child: LeaveStatCard(
                                  label: 'Rechazados',
                                  value: stats['rechazados'].toString(),
                                  icon: Icons.cancel_rounded,
                                  color: AppColors.errorRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 200,
                                child: LeaveStatCard(
                                  label: 'Total Días',
                                  value: stats['diasTotales'].toString(),
                                  icon: Icons.calendar_today_rounded,
                                  color: AppColors.infoBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filtros
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: LeaveFiltersSection(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  ),
                ),

                // Lista de solicitudes
                if (permissions.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_note_rounded,
                            size: 64,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? 'No hay solicitudes'
                                : 'No hay solicitudes ${_getFilterLabel()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Las solicitudes del equipo aparecerán aquí',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final request = permissions[index];
                          return RequestCard(
                            request: request,
                            onTap: () async {
                              // Navegar al detalle para aprobar/rechazar
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManagerLeaveDetailView(
                                    request: request,
                                  ),
                                ),
                              );
                              // Si cambió algo (aprobó/rechazó), recargar
                              if (changed == true) {
                                ref.invalidate(managerTeamPermissionsProvider);
                              }
                            },
                          );
                        },
                        childCount: permissions.length,
                      ),
                    ),
                  ),

                // Spacing al final
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryRed,
            ),
          ),
          error: (error, _) => _ErrorState(
            title: 'Error cargando permisos',
            message: '$error',
            onRetry: () => ref.invalidate(managerTeamPermissionsProvider),
          ),
        ),
      ),
    );
  }

  Map<String, int> _calculateStats(List<SolicitudesPermisos> requests) {
    int pendientes = 0;
    int aprobados = 0;
    int rechazados = 0;
    int diasTotales = 0;

    for (var request in requests) {
      if (request.estado == EstadoAprobacion.pendiente) {
        pendientes++;
      } else if (request.estado == EstadoAprobacion.aprobadoManager ||
          request.estado == EstadoAprobacion.aprobadoRrhh) {
        aprobados++;
        diasTotales += request.diasTotales;
      } else if (request.estado == EstadoAprobacion.rechazado) {
        rechazados++;
      }
    }

    return {
      'pendientes': pendientes,
      'aprobados': aprobados,
      'rechazados': rechazados,
      'diasTotales': diasTotales,
    };
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case EstadoAprobacion.pendiente:
        return 'pendientes';
      case EstadoAprobacion.aprobadoManager:
      case EstadoAprobacion.aprobadoRrhh:
        return 'aprobadas';
      case EstadoAprobacion.rechazado:
        return 'rechazadas';
      case EstadoAprobacion.canceladoUsuario:
        return 'canceladas';
      default:
        return '';
    }
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
