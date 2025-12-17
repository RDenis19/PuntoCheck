import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_team_member_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista del equipo del manager (3.2).
///
/// Muestra la lista de empleados asignados al manager:
/// - Filtrados por sucursales donde es encargado
/// - Solo empleados (rol=employee) y no eliminados
/// - Con búsqueda por nombre/apellido
class ManagerTeamView extends ConsumerStatefulWidget {
  const ManagerTeamView({super.key});

  @override
  ConsumerState<ManagerTeamView> createState() => _ManagerTeamViewState();
}

class _ManagerTeamViewState extends ConsumerState<ManagerTeamView> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  bool _includeInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(
      _includeInactive
          ? managerTeamAllProvider(_searchQuery)
          : managerTeamProvider(_searchQuery),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: AppColors.primaryRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Equipo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neutral900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Empleados a tu cargo',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                   // Barra de búsqueda
                   TextField(
                     controller: _searchController,
                     onChanged: (_) => _onSearchChanged(),
                     decoration: InputDecoration(
                       hintText: 'Buscar por nombre o apellido...',
                       prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.neutral100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Activos'),
                          selected: !_includeInactive,
                          onSelected: (_) =>
                              setState(() => _includeInactive = false),
                          selectedColor:
                              AppColors.primaryRed.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: !_includeInactive
                                ? AppColors.primaryRed
                                : AppColors.neutral700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _includeInactive,
                          onSelected: (_) =>
                              setState(() => _includeInactive = true),
                          selectedColor:
                              AppColors.primaryRed.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _includeInactive
                                ? AppColors.primaryRed
                                : AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                 ],
               ),
             ),

            // Lista de empleados
            Expanded(
              child: teamAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar el equipo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (team) {
                  if (team.isEmpty) {
                    return const EmptyState(
                      title: 'Sin empleados',
                      message:
                          'No tienes empleados asignados a tu cargo.\nContacta al administrador.',
                      icon: Icons.people_outline,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(
                        _includeInactive
                            ? managerTeamAllProvider(_searchQuery)
                            : managerTeamProvider(_searchQuery),
                      );
                    },
                    color: AppColors.primaryRed,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: team.length + 1, // +1 para el header
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Header con contador
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${team.length} ${team.length == 1 ? 'empleado' : 'empleados'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutral700,
                                  ),
                                ),
                                if (_searchQuery != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Filtrado',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        final employee = team[index - 1];

                        // Obtener horario del empleado desde la lista de horarios (si ya fue cargada por el provider en otro lado o aquí)
                        // Para evitar sobrecarga, podemos usar ref.watch(managerTeamSchedulesProvider(null)) si queremos eager loading
                        // O simplemente dejarlo vacío si no es crítico.
                        // Pero el usuario lo pidió. Vamos a intentar obtenerlo del provider de horarios.
                        final schedulesAsync = ref.watch(
                          managerTeamSchedulesProvider(null),
                        ); // Cacheado
                        final scheduleName = schedulesAsync.maybeWhen(
                          data: (schedules) {
                            final empSchedule = schedules.firstWhere(
                              (s) => s['perfil_id'] == employee.id,
                              orElse: () =>
                                  <
                                    String,
                                    dynamic
                                  >{}, // Retornar mapa vacío en lugar de null
                            );
                            if (empSchedule.isEmpty) return null;
                            return empSchedule['plantillas_horarios']['nombre']
                                as String?;
                          },
                          orElse: () => null,
                        );

                        return ManagerTeamMemberCard(
                          employee: employee,
                          scheduleName: scheduleName,
                          // onTap removido - usar navegación default del card
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
    );
  }
}
