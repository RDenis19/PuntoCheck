import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/admin/widgets/permission_type_chip.dart';
import 'package:puntocheck/presentation/admin/widgets/status_badge.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card moderno para mostrar una solicitud de permiso
class RequestCard extends StatefulWidget {
  final SolicitudesPermisos request;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  String? _employeeName;
  String? _employeePhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      final response = await supabase
          .from('perfiles')
          .select('nombres, apellidos, foto_perfil_url')
          .eq('id', widget.request.solicitanteId)
          .single();

      if (mounted) {
        setState(() {
          _employeeName = '${response['nombres']} ${response['apellidos']}';
          _employeePhotoUrl = response['foto_perfil_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _employeeName = 'Empleado';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: AppColors.neutral900.withValues(alpha: 0.08),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: _getGradientByStatus(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColorByStatus(),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Empleado + Estado
                Row(
                  children: [
                    // Avatar
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    // Nombre y fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 100,
                                  height: 16,
                                  child: LinearProgressIndicator(
                                    backgroundColor: AppColors.neutral200,
                                  ),
                                )
                              : Text(
                                  _employeeName ?? 'Cargando...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.neutral900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCreatedDate(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Estado badge
                    if (widget.request.estado != null)
                      StatusBadge(
                        estado: widget.request.estado!,
                        compact: true,
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Tipo de permiso
                PermissionTypeChip(
                  tipo: widget.request.tipo,
                  compact: false,
                ),

                const SizedBox(height: 14),

                // Fechas y días
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Fecha inicio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Desde',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(widget.request.fechaInicio),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.neutral400,
                      ),
                      const SizedBox(width: 8),
                      // Fecha fin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hasta',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(widget.request.fechaFin),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Días totales
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${widget.request.diasTotales}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'días',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Motivo (si existe)
                if (widget.request.motivoDetalle != null &&
                    widget.request.motivoDetalle!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.infoBlue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 18,
                          color: AppColors.infoBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.request.motivoDetalle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral900,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
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
        image: _employeePhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(_employeePhotoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _employeePhotoUrl == null
          ? const Center(
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
    );
  }

  LinearGradient _getGradientByStatus() {
    if (widget.request.estado == null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.neutral100.withValues(alpha: 0.3),
        ],
      );
    }

    Color baseColor;
    if (widget.request.estado == EstadoAprobacion.pendiente) {
      baseColor = AppColors.warningOrange;
    } else if (widget.request.estado == EstadoAprobacion.aprobadoManager ||
               widget.request.estado == EstadoAprobacion.aprobadoRrhh) {
      baseColor = AppColors.successGreen;
    } else if (widget.request.estado == EstadoAprobacion.rechazado) {
      baseColor = AppColors.errorRed;
    } else { // cancelado_usuario
      baseColor = AppColors.neutral600;
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        baseColor.withValues(alpha: 0.03),
      ],
    );
  }

  Color _getBorderColorByStatus() {
    if (widget.request.estado == null) {
      return AppColors.neutral300;
    }

    if (widget.request.estado == EstadoAprobacion.pendiente) {
      return AppColors.warningOrange;
    } else if (widget.request.estado == EstadoAprobacion.aprobadoManager ||
               widget.request.estado == EstadoAprobacion.aprobadoRrhh) {
      return AppColors.successGreen;
    } else if (widget.request.estado == EstadoAprobacion.rechazado) {
      return AppColors.errorRed;
    } else { // cancelado_usuario
      return AppColors.neutral600;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatCreatedDate() {
    if (widget.request.creadoEn == null) return 'Sin fecha';

    final now = DateTime.now();
    final diff = now.difference(widget.request.creadoEn!);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Hace ${diff.inMinutes} min';
      }
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return _formatDate(widget.request.creadoEn!);
    }
  }
}
