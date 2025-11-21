import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/providers/organization_provider.dart';
import 'package:puntocheck/providers/auth_provider.dart';

class AparienciaAppView extends ConsumerStatefulWidget {
  const AparienciaAppView({super.key});

  @override
  ConsumerState<AparienciaAppView> createState() => _AparienciaAppViewState();
}

class _AparienciaAppViewState extends ConsumerState<AparienciaAppView> {
  final _nombreAppController = TextEditingController(text: 'PuntoCheck');
  final _colorController = TextEditingController(text: '#EB283D');

  @override
  void dispose() {
    _nombreAppController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveAppearance() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    if (profile == null || profile.organizationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener la organización')),
      );
      return;
    }

    // Preparar datos de configuración
    final updates = {
      'brand_name': _nombreAppController.text,
      'brand_color': _colorController.text,
      // 'logo_url': // TODO: Implementar upload de logo con StorageService
    };

    final controller = ref.read(organizationControllerProvider.notifier);
    await controller.updateConfig(profile.organizationId!, updates);

    final state = ref.read(organizationControllerProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apariencia guardada exitosamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationControllerProvider);
    final isLoading = orgState.isLoading;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apariencia App'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personalización de Marca',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // TODO: Implementar upload de logo usando StorageService
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de subir logo en desarrollo.')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          color: AppColors.primaryRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subir logo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.backgroundDark,
                                ),
                              ),
                              Text(
                                'Tamaño recomendado: 512x512px (PNG o JPG)',
                                style: TextStyle(
                                  color: AppColors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nombre de la aplicación',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreAppController,
                  decoration: _inputDecoration('Mi Asistencia'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Color principal de la marca',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _colorController,
                        decoration: _inputDecoration('#EB283D'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _colorPreview(
                        AppColors.primaryRed.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _colorPreview(AppColors.primaryRed)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _colorPreview(
                        AppColors.primaryRed.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vista previa de tonos derivados.',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedDarkButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: isLoading ? 'Guardando...' : 'Guardar Cambios',
            enabled: !isLoading,
            onPressed: _saveAppearance,
          ),
        ],
      ),
    );
  }

  Widget _colorPreview(Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryRed),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

