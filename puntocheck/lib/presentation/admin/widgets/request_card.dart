import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/admin/widgets/permission_type_chip.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card moderno para mostrar una solicitud de permiso
/// Estilo limpio: Fondo blanco, borde ROJO (o del color primario) para destacar.
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Fondo SIEMPRE blanco
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // MARCO ROJO para destacar, como solicitó el usuario
          color: AppColors.primaryRed.withValues(alpha: 0.3), 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Avatar + Nombre/Fecha + Estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    // Info Central
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLoading
                              ? Container(
                                  width: 120,
                                  height: 16,
                                  color: AppColors.neutral200,
                                )
                              : Text(
                                  _employeeName ?? 'Empleado',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.neutral900,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(widget.request.creadoEn ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Estado Pill
                    _buildStatusPill(),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF3F4F6), thickness: 1),
                const SizedBox(height: 16),

                // 2. Chip de Tipo (Ej: Vacaciones)
                PermissionTypeChip(
                  tipo: widget.request.tipo,
                  compact: true,
                ),
                
                const SizedBox(height: 20),

                // 3. Layout de Fechas y Días
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Row(
                    children: [
                      // Fechas Desde -> Hasta
                      Expanded(
                        child: Row(
                          children: [
                            _buildDateColumn('Desde', widget.request.fechaInicio),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AppColors.neutral400,
                              ),
                            ),
                            _buildDateColumn('Hasta', widget.request.fechaFin),
                          ],
                        ),
                      ),
                      // Caja Roja de Días
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${widget.request.diasTotales}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'días',
                              style: TextStyle(
                                fontSize: 11,
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

                // 4. Motivo / Footer (si existe)
                if (widget.request.motivoDetalle != null &&
                    widget.request.motivoDetalle!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.request.motivoDetalle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral700,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
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

  Widget _buildDateColumn(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(date),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
        image: _employeePhotoUrl != null
            ? DecorationImage(
                image: NetworkImage(_employeePhotoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _employeePhotoUrl == null
          ? const Center(
              child: Icon(Icons.person_rounded, color: AppColors.neutral400, size: 26),
            )
          : null,
    );
  }

  /// Construye el badge de estado con color
  Widget _buildStatusPill() {
    Color color;
    String text;
    IconData icon;

    final estado = widget.request.estado;

    if (estado == null || estado == EstadoAprobacion.pendiente) {
      color = const Color(0xFFF59E0B); // Amber 600
      text = 'Pendiente';
      icon = Icons.access_time_rounded;
    } else if (estado == EstadoAprobacion.aprobadoManager) {
      color = AppColors.successGreen;
      text = 'Aprob. Mng';
      icon = Icons.check_circle_outline_rounded;
    } else if (estado == EstadoAprobacion.aprobadoRrhh) {
      color = AppColors.successGreen;
      text = 'Aprobado';
      icon = Icons.check_circle_rounded;
    } else if (estado == EstadoAprobacion.rechazado) {
      color = AppColors.errorRed;
      text = 'Rechazado';
      icon = Icons.cancel_rounded;
    } else {
      color = AppColors.neutral500;
      text = 'Cancelado';
      icon = Icons.block_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
