import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_new_schedule_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_schedule_detail_view.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/schedule_template_card.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Provider para plantillas de horarios
final _schedulesProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null) throw Exception('No org ID');
  return ScheduleService.instance.getScheduleTemplates(orgId);
});

/// Vista principal para gestión de plantillas de horarios
class OrgAdminSchedulesView extends ConsumerWidget {
  const OrgAdminSchedulesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(_schedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Horarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(_schedulesProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_schedulesProvider);
            await ref.read(_schedulesProvider.future);
          },
          child: schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) {
                return EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Sin plantillas de horarios',
                  subtitle:
                      'Crea tu primera plantilla para asignar a empleados',
                  primaryLabel: 'Crear Plantilla',
                  onPrimary: () => _navigateToNew(context, ref),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return ScheduleTemplateCard(
                    template: schedule,
                    onTap: () => _navigateToDetail(context, ref, schedule),
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
                      'Error cargando horarios',
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
                      onPressed: () => ref.invalidate(_schedulesProvider),
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
        onPressed: () => _navigateToNew(context, ref),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Plantilla'),
      ),
    );
  }

  Future<void> _navigateToNew(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OrgAdminNewScheduleView()),
    );

    if (changed == true) {
      ref.invalidate(_schedulesProvider);
    }
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    WidgetRef ref,
    PlantillasHorarios schedule,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrgAdminScheduleDetailView(schedule: schedule),
      ),
    );

    if (changed == true) {
      ref.invalidate(_schedulesProvider);
    }
  }
}
