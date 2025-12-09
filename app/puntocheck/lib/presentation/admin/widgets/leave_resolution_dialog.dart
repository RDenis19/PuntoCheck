import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Dialog para aprobar o rechazar una solicitud de permiso
class LeaveResolutionDialog extends StatefulWidget {
  final bool isApproval; // true = aprobar, false = rechazar
  final VoidCallback onConfirm;

  const LeaveResolutionDialog({
    super.key,
    required this.isApproval,
    required this.onConfirm,
  });

  @override
  State<LeaveResolutionDialog> createState() => _LeaveResolutionDialogState();
}

class _LeaveResolutionDialogState extends State<LeaveResolutionDialog> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isApproval ? AppColors.successGreen : AppColors.errorRed;
    final icon = widget.isApproval ? Icons.check_circle : Icons.cancel;
    final title = widget.isApproval ? 'Aprobar Solicitud' : 'Rechazar Solicitud';
    final actionText = widget.isApproval ? 'Aprobar' : 'Rechazar';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isApproval
                  ? '¿Estás seguro de aprobar esta solicitud de permiso?'
                  : '¿Estás seguro de rechazar esta solicitud de permiso?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.isApproval
                    ? 'Comentario (opcional)'
                    : 'Motivo del rechazo *',
                hintText: 'Escribe un comentario...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.neutral100,
              ),
              validator: (value) {
                if (!widget.isApproval && (value == null || value.trim().isEmpty)) {
                  return 'El motivo del rechazo es obligatorio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.neutral700),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _commentController.text.trim());
              widget.onConfirm();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}
