import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/image_picker_button.dart';
import 'package:puntocheck/presentation/shared/widgets/location_display.dart';

class RegistroAsistenciaView extends StatefulWidget {
  const RegistroAsistenciaView({super.key});

  @override
  State<RegistroAsistenciaView> createState() => _RegistroAsistenciaViewState();
}

class _RegistroAsistenciaViewState extends State<RegistroAsistenciaView> {
  File? _selectedImage;
  Position? _currentPosition;

  void _onConfirm() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar una foto de evidencia')),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes obtener tu ubicación actual')),
      );
      return;
    }

    // TODO(backend): enviar foto, geolocalización y hora al backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Asistencia registrada correctamente (mock).'),
        backgroundColor: Colors.green,
      ),
    );
  }

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
            ImagePickerButton(
              imageFile: _selectedImage,
              onImageSelected: (file) {
                setState(() {
                  _selectedImage = file;
                });
              },
              label: 'Tomar Foto de Evidencia',
            ),
            const SizedBox(height: 24),
            LocationDisplay(
              onLocationChanged: (position) {
                setState(() {
                  _currentPosition = position;
                });
              },
            ),
            const SizedBox(height: 24),
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
              onPressed: _onConfirm,
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




