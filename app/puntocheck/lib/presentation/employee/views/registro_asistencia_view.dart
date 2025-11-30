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

    final activeShift = await ref.read(activeShiftProvider.future);
    final controller = ref.read(attendanceControllerProvider.notifier);
    final location = GeoLocation(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );

    if (activeShift == null) {
      await controller.checkIn(
        location: location,
        photoFile: _selectedImage!,
        orgId: profile.organizationId!,
      );
    } else {
      await controller.checkOut(
        shiftId: activeShift.id,
        location: location,
        orgId: profile.organizationId!,
        photoFile: _selectedImage!,
      );
    }

    final state = ref.read(attendanceControllerProvider);

    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activeShift == null
              ? 'Entrada registrada correctamente.'
              : 'Salida registrada correctamente.'),
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
    final activeShiftAsync = ref.watch(activeShiftProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: activeShiftAsync.when(
          data: (shift) => Text(
            shift == null ? 'Registrar Entrada' : 'Registrar Salida',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
          ),
          loading: () => const Text(
            'Registrar Asistencia',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
          ),
          error: (_, __) => const Text(
            'Registrar Asistencia',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.backgroundDark,
            ),
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.infoBlue.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.infoBlue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.infoBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Importante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.backgroundDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu foto y ubicación serán registradas de forma segura en el sistema de asistencia.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.backgroundDark.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los datos se guardarán cifrados como evidencia del registro.',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.3,
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
              text: activeShiftAsync.when(
                data: (shift) => isLoading
                    ? 'Registrando...'
                    : shift == null
                        ? 'Confirmar Entrada'
                        : 'Confirmar Salida',
                loading: () => isLoading ? 'Registrando...' : 'Confirmar',
                error: (_, __) => isLoading ? 'Registrando...' : 'Confirmar',
              ),
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

