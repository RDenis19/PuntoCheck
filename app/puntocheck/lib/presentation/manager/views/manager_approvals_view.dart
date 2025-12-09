import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/presentation/manager/widgets/manager_permission_card.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de aprobaciones de permisos del equipo del Manager (Fase 3).
/// 
/// Permite al manager:
/// - Ver permisos de su equipo (pendientes o todos)
/// - Aprobar permisos pendientes
/// - Rechazar permisos pendientes con comentario
class ManagerApprovalsView extends ConsumerStatefulWidget {
  const ManagerApprovalsView({super.key});

  @override
  ConsumerState<ManagerApprovalsView> createState() =>
      _ManagerApprovalsViewState();
}

class _ManagerApprovalsViewState extends ConsumerState<ManagerApprovalsView> {
  bool _showOnlyPending = true;

  @override
  Widget build(BuildContext context) {
    final permissionsAsync =
        ref.watch(managerTeamPermissionsProvider(_showOnlyPending));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobar Permisos'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(managerTeamPermissionsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented control: Pendientes / Todos
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Pendientes',
                      isSelected: _showOnlyPending,
                      onTap: () => setState(() => _showOnlyPending = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TabButton(
                      label: 'Todos',
                      isSelected: !_showOnlyPending,
                      onTap: () => setState(() => _showOnlyPending = false),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de permisos
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(managerTeamPermissionsProvider);
                },
                color: AppColors.primaryRed,
                child: permissionsAsync.when(
                  data: (permissions) {
                    if (permissions.isEmpty) {
                      return EmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: _showOnlyPending
                            ? 'Sin permisos pendientes'
                            : 'Sin permisos',
                        message: _showOnlyPending
                            ? 'No hay solicitudes de permisos pendientes por aprobar'
                            : 'No hay solicitudes de permisos del equipo',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: permissions.length,
                      itemBuilder: (context, index) {
                        final permission = permissions[index];
                        final employeeProfile = ref
                            .watch(managerPersonProvider(permission.solicitanteId))
                            .valueOrNull;

                        final employeeName = employeeProfile != null
                            ? '${employeeProfile.nombres} ${employeeProfile.apellidos}'
                            : 'Cargando...';

                        return ManagerPermissionCard(
                          permission: permission,
                          employeeName: employeeName,
                          // onTap removido - usar navegación default del card
                          onApprove: permission.estado == EstadoAprobacion.pendiente
                              ? () => _handleApprove(context, permission.id)
                              : null,
                          onReject: permission.estado == EstadoAprobacion.pendiente
                              ? () => _handleReject(context, permission.id)
                              : null,
                        );
                      },
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
                            'Error cargando permisos',
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
                              ref.invalidate(managerTeamPermissionsProvider);
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
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, String requestId) async {
    final controller = ref.read(managerPermissionControllerProvider.notifier);

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: '¿Aprobar permiso?',
        message: '¿EstásSeguro que deseas aprobar esta solicitud de permiso?',
        confirmLabel: 'Aprobar',
        confirmColor: AppColors.successGreen,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirm != true) return;

    try {
      await controller.approve(
        requestId: requestId,
        comment: 'Aprobado por el manager',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso aprobado exitosamente'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Invalidar provider para refrescar lista
      ref.invalidate(managerTeamPermissionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, String requestId) async {
    final controller = ref.read(managerPermissionControllerProvider.notifier);

    // Mostrar diálogo para ingresar motivo de rechazo
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (comment == null || comment.trim().isEmpty) return;

    try {
      await controller.reject(
        requestId: requestId,
        comment: comment,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso rechazado'),
            backgroundColor: AppColors.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Invalidar provider para refrescar lista
      ref.invalidate(managerTeamPermissionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ============================================================================
// Widgets auxiliares
// ============================================================================

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.neutral300,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isSelected ? Colors.white : AppColors.neutral700,
          ),
        ),
      ),
    );
  }
}

class _ApprovalDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ApprovalDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Rechazar permiso',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Indica el motivo del rechazo:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ej: No se cumplen los requisitos...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
