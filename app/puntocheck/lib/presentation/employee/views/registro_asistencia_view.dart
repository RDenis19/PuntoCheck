import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/image_picker_button.dart';
import 'package:puntocheck/presentation/shared/widgets/location_display.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/models/geo_location.dart';

class RegistroAsistenciaView extends ConsumerStatefulWidget {
  const RegistroAsistenciaView({super.key});

  @override
  ConsumerState<RegistroAsistenciaView> createState() => _RegistroAsistenciaViewState();
}

class _RegistroAsistenciaViewState extends ConsumerState<RegistroAsistenciaView> {
  File? _selectedImage;
  Position? _currentPosition;

  Future<void> _onConfirm() async {
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

    final profile = await ref.read(profileProvider.future);
    if (profile == null || profile.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener la organizacion')),
      );
      return;
    }

    // Llamar al controller
    await ref.read(attendanceControllerProvider.notifier).checkIn(
      location: GeoLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
      photoFile: _selectedImage!,
      orgId: profile.organizationId!,
    );

    final state = ref.read(attendanceControllerProvider);
    
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia registrada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final isLoading = attendanceState.isLoading;

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
                          'Los datos se guardarAn cifrados como evidencia del registro.',
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
              text: isLoading ? 'Registrando...' : 'Confirmar Entrada',
              enabled: !isLoading,
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

