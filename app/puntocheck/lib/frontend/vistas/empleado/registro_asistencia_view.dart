import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';
import 'package:puntocheck/frontend/vistas/empleado/widgets/registro_widgets.dart';

class RegistroAsistenciaView extends StatelessWidget {
  const RegistroAsistenciaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Registrar Asistencia',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistroCircleAction(
              title: 'Agregar Foto',
              subtitle: 'Toca para capturar tu foto',
              icon: Icons.photo_camera_outlined,
              onTap: () {
                // TODO(backend): abrir la cámara o galería para capturar y subir
                // la evidencia visual del registro de asistencia.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Captura de foto (mock).')),
                );
              },
            ),
            const SizedBox(height: 24),
            const RegistroLocationCard(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.infoBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tu foto y ubicación serán registradas de forma segura en el sistema de asistencia.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        // TODO(backend): explicar términos de privacidad y almacenamiento real
                        // de los datos para que el usuario sepa cómo se protegerá la información.
                        Text(
                          'Los datos se guardarán cifrados como evidencia del registro.',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Confirmar Entrada',
              onPressed: () {
                // TODO(backend): enviar foto, geolocalización y hora al backend para
                // guardar un registro auditado y calcular horas trabajadas.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Asistencia registrada (mock).'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Al confirmar, aceptas que tu información sea registrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
