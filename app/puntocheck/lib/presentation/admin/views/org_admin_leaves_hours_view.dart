import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminLeavesAndHoursView extends ConsumerWidget {
  const OrgAdminLeavesAndHoursView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(orgAdminPermissionsProvider(true));
    final controller = ref.read(orgAdminPermissionControllerProvider.notifier);
    final state = ref.watch(orgAdminPermissionControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(orgAdminPermissionsProvider(true).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Permisos pendientes',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          requestsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyState(
                  icon: Icons.event_note_outlined,
                  text: 'No hay solicitudes pendientes.',
                );
              }
              return Column(
                children: list.map((req) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _RequestTile(
                        request: req,
                        isProcessing: state.isLoading,
                        onApprove: () => controller.resolve(
                          requestId: req.id,
                          status: EstadoAprobacion.aprobado,
                        ),
                        onReject: () => controller.resolve(
                          requestId: req.id,
                          status: EstadoAprobacion.rechazado,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Banco de horas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.neutral900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const _EmptyState(
            icon: Icons.schedule_outlined,
            text:
                'Próximo paso: listar saldos por empleado y permitir agregar registros usando ComplianceService.addHourRecord().',
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final SolicitudesPermisos request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isProcessing;

  const _RequestTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final start = '${request.fechaInicio.day}/${request.fechaInicio.month}';
    final end = '${request.fechaFin.day}/${request.fechaFin.month}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.tipo.value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Empleado: ${request.solicitanteId}',
          style: const TextStyle(color: AppColors.neutral700),
        ),
        Text(
          '$start - $end (${request.diasTotales} días)',
          style: const TextStyle(color: AppColors.neutral700),
        ),
        if (request.motivoDetalle != null) ...[
          const SizedBox(height: 4),
          Text(request.motivoDetalle!),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : onReject,
                icon: const Icon(Icons.close, color: AppColors.errorRed),
                label: const Text(
                  'Rechazar',
                  style: TextStyle(color: AppColors.errorRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onApprove,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                ),
                label: Text(isProcessing ? 'Procesando...' : 'Aprobar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.neutral700),
            ),
          ),
        ],
      ),
    );
  }
}
