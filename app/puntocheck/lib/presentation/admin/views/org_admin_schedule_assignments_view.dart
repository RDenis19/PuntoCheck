import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/asignaciones_horarios.dart';
import 'package:puntocheck/presentation/admin/widgets/assign_schedule_sheet.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Provider para asignaciones de horarios
final _assignmentsProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null) throw Exception('No org ID');

  // Obtener asignaciones activas
  final response = await supabase
      .from('asignaciones_horarios')
      .select('*, perfiles!inner(nombres, apellidos), plantillas_horarios!inner(nombre)')
      .eq('organizacion_id', orgId)
      .or('fecha_fin.is.null,fecha_fin.gte.${DateTime.now().toIso8601String()}')
      .order('creado_en', ascending: false);

  return response;
});

/// Vista para gestionar asignaciones de horarios
class OrgAdminScheduleAssignmentsView extends ConsumerWidget {
  const OrgAdminScheduleAssignmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(_assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignaciones de Horarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(_assignmentsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_assignmentsProvider);
            await ref.read(_assignmentsProvider.future);
          },
          child: assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Sin asignaciones',
                  subtitle: 'Asigna horarios a tus empleados para comenzar',
                  primaryLabel: 'Asignar Horario',
                  onPrimary: () => _openAssignSheet(context, ref),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return _AssignmentCard(
                    assignment: assignment,
                    onDelete: () => _deleteAssignment(context, ref, assignment['id']),
                  );
                },
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
                      'Error cargando asignaciones',
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
                      onPressed: () => ref.invalidate(_assignmentsProvider),
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
        onPressed: () => _openAssignSheet(context, ref),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Asignar Horario'),
      ),
    );
  }

  void _openAssignSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignScheduleSheet(
        onAssigned: (_) {
          ref.invalidate(_assignmentsProvider);
        },
      ),
    );
  }

  Future<void> _deleteAssignment(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Asignación'),
        content: const Text(
          '¿Estás seguro de eliminar esta asignación de horario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('asignaciones_horarios')
            .delete()
            .eq('id', assignmentId);

        ref.invalidate(_assignmentsProvider);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asignación eliminada')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final employee = assignment['perfiles'] as Map<String, dynamic>?;
    final template = assignment['plantillas_horarios'] as Map<String, dynamic>?;
    final fechaInicio = DateTime.parse(assignment['fecha_inicio']);
    final fechaFin = assignment['fecha_fin'] != null
        ? DateTime.parse(assignment['fecha_fin'])
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.neutral200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Empleado
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.8),
                        AppColors.primaryRed,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee != null
                            ? '${employee['nombres']} ${employee['apellidos']}'
                            : 'Empleado desconocido',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.neutral900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template?['nombre'] ?? 'Sin plantilla',
                        style: const TextStyle(
                          color: AppColors.neutral600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Fechas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desde',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(fechaInicio),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hasta',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fechaFin != null
                              ? _formatDate(fechaFin)
                              : 'Indefinido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: fechaFin != null
                                ? AppColors.neutral900
                                : AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
