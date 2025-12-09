import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/manager/views/manager_leave_detail_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Card para mostrar solicitud de permiso en lista del Manager.
/// 
/// Muestra información resumida del permiso:
/// - Nombre del empleado
/// - Tipo de permiso
/// - Fechas y duración
/// - Estado
/// - Botones de acción si está pendiente
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
        side: BorderSide(
          color: AppColors.neutral200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap ??
            () async {
              // Navegar a la vista de detalle
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerLeaveDetailView(request: permission),
                ),
              );
              // result será true si se aprobó/rechazó el permiso
            },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Empleado + Estado
              Row(
                children: [
                  // Avatar circular
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employeeName.isNotEmpty ? employeeName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre y estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
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
                                  fontWeight: FontWeight.w700,
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

              // Tipo de permiso
              _PermissionTypeChip(tipo: permission.tipo),

              const SizedBox(height: 12),

              // Fechas y duración
              Row(
                children: [
                  Icon(
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
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // Botones de acción si está pendiente
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

  String _formatDate(DateTime date) {
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
      case EstadoAprobacion.aprobadoRrhh:
        return _StatusConfig(
          label: 'Aprobado',
          icon: Icons.check_circle,
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
          icon: Icons.remove_circle,
          backgroundColor: AppColors.neutral300.withValues(alpha: 0.1),
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

// ============================================================================
// Widgets auxiliares
// ============================================================================

class _PermissionTypeChip extends StatelessWidget {
  final TipoPermiso tipo;

  const _PermissionTypeChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.15),
            config.color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _getTypeConfig(TipoPermiso tipo) {
    switch (tipo) {
      case TipoPermiso.vacaciones:
        return _TypeConfig(
          label: 'VACACIONES',
          icon: Icons.beach_access,
          color: const Color(0xFF0288D1), // Blue 700
        );
      case TipoPermiso.enfermedad:
        return _TypeConfig(
          label: 'ENFERMEDAD',
          icon: Icons.medical_services,
          color: const Color(0xFFC62828), // Red 800
        );
      case TipoPermiso.maternidadPaternidad:
        return _TypeConfig(
          label: 'MATERNIDAD/PATERNIDAD',
          icon: Icons.family_restroom,
          color: const Color(0xFF6A1B9A), // Purple 800
        );
      case TipoPermiso.calamidadDomestica:
        return _TypeConfig(
          label: 'CALAMIDAD',
          icon: Icons.warning_amber,
          color: AppColors.warningOrange,
        );
      case TipoPermiso.legalVotacion:
        return _TypeConfig(
          label: 'LEGAL/VOTACIÓN',
          icon: Icons.how_to_vote,
          color: const Color(0xFF2E7D32), // Green 800
        );
      case TipoPermiso.otro:
        return _TypeConfig(
          label: 'OTRO',
          icon: Icons.more_horiz,
          color: AppColors.neutral700,
        );
    }
  }
}

// ============================================================================
// Modelos auxiliares
// ============================================================================

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

class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
