import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/manager/views/manager_leave_detail_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card para mostrar una solicitud de permiso en la lista del Manager.
class ManagerPermissionCard extends StatelessWidget {
  final SolicitudesPermisos permission;
  final String employeeName;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ManagerPermissionCard({
    super.key,
    required this.permission,
    required this.employeeName,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = permission.estado == EstadoAprobacion.pendiente;
    final statusConfig = _getStatusConfig(permission.estado);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutral200, width: 1.5),
      ),
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerLeaveDetailView(request: permission),
                ),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employeeName.isNotEmpty
                            ? employeeName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusConfig.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusConfig.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusConfig.icon,
                                size: 14,
                                color: statusConfig.textColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusConfig.label,
                                style: TextStyle(
                                  color: statusConfig.textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
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
              const SizedBox(height: 14),
              _PermissionTypeChip(tipo: permission.tipo),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(permission.fechaInicio)} - ${_formatDate(permission.fechaFin)}',
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${permission.diasTotales} ${permission.diasTotales == 1 ? 'día' : 'días'}',
                      style: const TextStyle(
                        color: AppColors.infoBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (isPending && (onApprove != null || onReject != null)) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorRed,
                            side: const BorderSide(
                              color: AppColors.errorRed,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (onReject != null && onApprove != null)
                      const SizedBox(width: 10),
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  _StatusConfig _getStatusConfig(EstadoAprobacion? estado) {
    switch (estado) {
      case EstadoAprobacion.pendiente:
        return _StatusConfig(
          label: 'Pendiente',
          icon: Icons.schedule,
          backgroundColor: AppColors.warningOrange.withValues(alpha: 0.1),
          borderColor: AppColors.warningOrange.withValues(alpha: 0.3),
          textColor: AppColors.warningOrange,
        );
      case EstadoAprobacion.aprobadoManager:
        return _StatusConfig(
          label: 'Aprobado (Manager)',
          icon: Icons.check_circle,
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
          borderColor: AppColors.successGreen.withValues(alpha: 0.3),
          textColor: AppColors.successGreen,
        );
      case EstadoAprobacion.aprobadoRrhh:
        return _StatusConfig(
          label: 'Aprobado (Final)',
          icon: Icons.verified_rounded,
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
          borderColor: AppColors.successGreen.withValues(alpha: 0.3),
          textColor: AppColors.successGreen,
        );
      case EstadoAprobacion.rechazado:
        return _StatusConfig(
          label: 'Rechazado',
          icon: Icons.cancel,
          backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
          borderColor: AppColors.errorRed.withValues(alpha: 0.3),
          textColor: AppColors.errorRed,
        );
      case EstadoAprobacion.canceladoUsuario:
        return _StatusConfig(
          label: 'Cancelado',
          icon: Icons.block,
          backgroundColor: AppColors.neutral200,
          borderColor: AppColors.neutral300,
          textColor: AppColors.neutral700,
        );
      default:
        return _StatusConfig(
          label: 'Desconocido',
          icon: Icons.help_outline,
          backgroundColor: AppColors.neutral200,
          borderColor: AppColors.neutral300,
          textColor: AppColors.neutral700,
        );
    }
  }
}

class _PermissionTypeChip extends StatelessWidget {
  final TipoPermiso tipo;

  const _PermissionTypeChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final label = _label(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryRed,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  static String _label(TipoPermiso tipo) {
    switch (tipo) {
      case TipoPermiso.enfermedad:
        return 'Enfermedad';
      case TipoPermiso.maternidadPaternidad:
        return 'Maternidad/Paternidad';
      case TipoPermiso.calamidadDomestica:
        return 'Calamidad doméstica';
      case TipoPermiso.vacaciones:
        return 'Vacaciones';
      case TipoPermiso.legalVotacion:
        return 'Votación (legal)';
      case TipoPermiso.otro:
        return 'Otro';
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
