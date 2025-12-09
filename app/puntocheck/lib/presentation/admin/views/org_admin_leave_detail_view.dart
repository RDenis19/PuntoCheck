import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/solicitudes_permisos.dart';
import 'package:puntocheck/presentation/admin/widgets/leave_resolution_dialog.dart';
import 'package:puntocheck/presentation/admin/widgets/permission_type_chip.dart';
import 'package:puntocheck/presentation/admin/widgets/status_badge.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/supabase_client.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de detalle completo de una solicitud de permiso
class OrgAdminLeaveDetailView extends ConsumerStatefulWidget {
  final SolicitudesPermisos request;

  const OrgAdminLeaveDetailView({
    super.key,
    required this.request,
  });

  @override
  ConsumerState<OrgAdminLeaveDetailView> createState() =>
      _OrgAdminLeaveDetailViewState();
}

class _OrgAdminLeaveDetailViewState
    extends ConsumerState<OrgAdminLeaveDetailView> {
  String? _employeeName;
  String? _employeePhotoUrl;
  String? _employeeCargo;
  String? _approverName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch employee data
      final employeeResponse = await supabase
          .from('perfiles')
          .select('nombres, apellidos, foto_perfil_url, cargo')
          .eq('id', widget.request.solicitanteId)
          .single();

      String? approverName;
      if (widget.request.aprobadoPorId != null) {
        final approverResponse = await supabase
            .from('perfiles')
            .select('nombres, apellidos')
            .eq('id', widget.request.aprobadoPorId!)
            .single();
        approverName =
            '${approverResponse['nombres']} ${approverResponse['apellidos']}';
      }

      if (mounted) {
        setState(() {
          _employeeName =
              '${employeeResponse['nombres']} ${employeeResponse['apellidos']}';
          _employeePhotoUrl = employeeResponse['foto_perfil_url'];
          _employeeCargo = employeeResponse['cargo'];
          _approverName = approverName;
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
    final controller = ref.read(orgAdminPermissionControllerProvider.notifier);
    final state = ref.watch(orgAdminPermissionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estado grande
                  _buildHeader(),
                  
                  const SizedBox(height: 20),

                  // Info del empleado
                  _buildEmployeeCard(),

                  const SizedBox(height: 16),

                  // Detalles del permiso
                  _buildDetailCard(),

                  const SizedBox(height: 16),

                  // Información de resolución (si está aprobada/rechazada)
                  if (widget.request.estado != EstadoAprobacion.pendiente)
                    _buildResolutionCard(),

                  // Botones de acción (solo si está pendiente)
                  if (widget.request.estado == EstadoAprobacion.pendiente) ...[
                    const SizedBox(height: 24),
                    _buildActionButtons(controller, state.isLoading),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getColor(),
            _getColor().withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _getIcon(),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          if (widget.request.estado != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed.withValues(alpha: 0.8),
                  AppColors.primaryRed,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
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
                      size: 32,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeName ?? 'Cargando...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                if (_employeeCargo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _employeeCargo!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.event_note, color: AppColors.neutral700),
                SizedBox(width: 12),
                Text(
                  'Detalles del Permiso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tipo
                _DetailRow(
                  label: 'Tipo',
                  value: PermissionTypeChip(tipo: widget.request.tipo),
                ),
                const SizedBox(height: 12),
                // Fechas
                _DetailRow(
                  label: 'Desde',
                  value: Text(_formatDate(widget.request.fechaInicio)),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Hasta',
                  value: Text(_formatDate(widget.request.fechaFin)),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Días totales',
                  value: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.request.diasTotales} días',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ),
                // Motivo
                if (widget.request.motivoDetalle != null &&
                    widget.request.motivoDetalle!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Motivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.request.motivoDetalle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                ],
                // Documento (si existe)
                if (widget.request.documentoSoporteUrl != null &&
                    widget.request.documentoSoporteUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Documento',
                    value: InkWell(
                      onTap: () {
                        // TODO: Abrir documento en navegador o viewer
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abriendo documento...'),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.attach_file,
                            size: 18,
                            color: AppColors.infoBlue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ver documento',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.infoBlue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Fecha de creación
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Fecha de solicitud',
                  value: Text(
                    widget.request.creadoEn != null
                        ? _formatDateTime(widget.request.creadoEn!)
                        : 'Sin fecha',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIcon(), color: _getColor()),
              const SizedBox(width: 12),
              Text(
                widget.request.estado == EstadoAprobacion.aprobadoManager ||
                    widget.request.estado == EstadoAprobacion.aprobadoRrhh
                    ? 'Solicitud Aprobada'
                    : 'Solicitud Rechazada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _getColor(),
                ),
              ),
            ],
          ),
          if (_approverName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Por: $_approverName',
              style: TextStyle(
                fontSize: 14,
                color: _getColor(),
              ),
            ),
          ],
          if (widget.request.fechaResolucion != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDateTime(widget.request.fechaResolucion!),
              style: TextStyle(
                fontSize: 13,
                color: _getColor().withValues(alpha: 0.8),
              ),
            ),
          ],
          if (widget.request.comentarioResolucion != null &&
              widget.request.comentarioResolucion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Comentario:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.request.comentarioResolucion!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(controller, bool isProcessing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : () => _handleReject(controller),
            icon: const Icon(Icons.close),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: const BorderSide(color: AppColors.errorRed, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : () => _handleApprove(controller),
            icon: const Icon(Icons.check_circle),
            label: Text(isProcessing ? 'Procesando...' : 'Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(controller) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => LeaveResolutionDialog(
        isApproval: true,
        onConfirm: () {},
      ),
    );

    if (comment != null) {
      await controller.resolve(
        requestId: widget.request.id,
        status: EstadoAprobacion.aprobadoManager, // Manager/Admin aprueba
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud aprobada exitosamente'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleReject(controller) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => LeaveResolutionDialog(
        isApproval: false,
        onConfirm: () {},
      ),
    );

    if (comment != null) {
      await controller.resolve(
        requestId: widget.request.id,
        status: EstadoAprobacion.rechazado,
        comment: comment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud rechazada'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Color _getColor() {
    if (widget.request.estado == null) return AppColors.neutral700;
    
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

  IconData _getIcon() {
    if (widget.request.estado == null) return Icons.help_outline;
    
    if (widget.request.estado == EstadoAprobacion.pendiente) {
      return Icons.pending_outlined;
    } else if (widget.request.estado == EstadoAprobacion.aprobadoManager ||
               widget.request.estado == EstadoAprobacion.aprobadoRrhh) {
      return Icons.check_circle;
    } else if (widget.request.estado == EstadoAprobacion.rechazado) {
      return Icons.cancel;
    } else { // cancelado_usuario
      return Icons.block;
    }
  }

  String _getStatusText() {
    if (widget.request.estado == null) return 'Sin estado';
    
    if (widget.request.estado == EstadoAprobacion.pendiente) {
      return 'PENDIENTE';
    } else if (widget.request.estado == EstadoAprobacion.aprobadoManager) {
      return 'APROBADO (MANAGER)';
    } else if (widget.request.estado == EstadoAprobacion.aprobadoRrhh) {
      return 'APROBADO (RRHH)';
    } else if (widget.request.estado == EstadoAprobacion.rechazado) {
      return 'RECHAZADO';
    } else { // cancelado_usuario
      return 'CANCELADO';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral600,
            fontWeight: FontWeight.w600,
          ),
        ),
        value,
      ],
    );
  }
}
