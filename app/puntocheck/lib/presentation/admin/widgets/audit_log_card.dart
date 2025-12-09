import 'package:flutter/material.dart';
import 'package:puntocheck/models/auditoria_log.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// Card para mostrar un log de auditoría
class AuditLogCard extends StatefulWidget {
  final AuditoriaLog log;

  const AuditLogCard({
    super.key,
    required this.log,
  });

  @override
  State<AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<AuditLogCard> {
  bool _isExpanded = false;

  IconData get _icon {
    if (widget.log.accion.contains('INSERT') ||
        widget.log.accion.contains('CREATE')) {
      return Icons.add_circle_outline;
    } else if (widget.log.accion.contains('UPDATE') ||
        widget.log.accion.contains('EDIT')) {
      return Icons.edit_outlined;
    } else if (widget.log.accion.contains('DELETE') ||
        widget.log.accion.contains('REMOVE')) {
      return Icons.delete_outline;
    }
    return Icons.sync_alt;
  }

  Color get _color {
    if (widget.log.accion.contains('INSERT') ||
        widget.log.accion.contains('CREATE')) {
      return AppColors.successGreen;
    } else if (widget.log.accion.contains('DELETE') ||
        widget.log.accion.contains('REMOVE')) {
      return AppColors.errorRed;
    } else if (widget.log.accion.contains('UPDATE')) {
      return AppColors.infoBlue;
    }
    return AppColors.neutral600;
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icono de acción
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.log.accion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (widget.log.tablaAfectada != null)
                          Text(
                            'Tabla: ${widget.log.tablaAfectada}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(widget.log.creadoEn),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Icono expandir
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
          
          // Detalles expandibles
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.log.usuarioResponsableId != null) ...[
                    _buildDetailRow(
                      'Usuario',
                      widget.log.usuarioResponsableId!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.log.ipOrigen != null) ...[
                    _buildDetailRow('IP', widget.log.ipOrigen!),
                    const SizedBox(height: 8),
                  ],
                  if (widget.log.detalleCambio != null) ...[
                    const Text(
                      'Detalles del cambio:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatJson(widget.log.detalleCambio!),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral900,
            ),
          ),
        ),
      ],
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
