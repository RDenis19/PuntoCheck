import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';

/// Dialog para mostrar detalles y resolver una alerta
class AlertDetailDialog extends StatefulWidget {
  final AlertasCumplimiento alert;
  final Future<void> Function(String status, String? justification) onResolve;

  const AlertDetailDialog({
    super.key,
    required this.alert,
    required this.onResolve,
  });

  @override
  State<AlertDetailDialog> createState() => _AlertDetailDialogState();
}

class _AlertDetailDialogState extends State<AlertDetailDialog> {
  final _justificationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  Color get _severityColor {
    switch (widget.alert.gravedad?.value ?? 'moderada') {
      case 'grave_legal':
        return AppColors.errorRed;
      case 'moderada':
        return AppColors.warningOrange;
      default:
        return AppColors.infoBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.shield_outlined, color: _severityColor, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detalle de Alerta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de incumplimiento
            _buildSection(
              'Tipo',
              widget.alert.tipoIncumplimiento,
              icon: Icons.warning_amber,
            ),
            const SizedBox(height: 16),

            // Detalle técnico
            if (widget.alert.detalleTecnico != null) ...[
              _buildSection(
                'Descripción',
                widget.alert.detalleTecnico?['descripcion'] ?? 'N/A',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 16),
            ],

            // Gravedad
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _severityColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.priority_high, color: _severityColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Gravedad: ${widget.alert.gravedad?.value ?? "Moderada"}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _severityColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de justificación
            TextField(
              controller: _justificationController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Justificación',
                hintText: 'Escribe una justificación...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.neutral100,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => _handleResolve('rechazado'),
          style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
          child: const Text('Rechazar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () => _handleResolve('justificado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Justificar'),
        ),
      ],
    );
  }

  Widget _buildSection(String label, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.neutral600),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.neutral900),
        ),
      ],
    );
  }

  Future<void> _handleResolve(String status) async {
    final justification = _justificationController.text.trim();
    
    if (justification.isEmpty && status == 'rechazado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes proporcionar una justificación para rechazar'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onResolve(status, justification.isEmpty ? null : justification);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
