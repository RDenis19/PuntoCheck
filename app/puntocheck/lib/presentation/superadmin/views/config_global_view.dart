import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

class ConfigGlobalView extends ConsumerStatefulWidget {
  const ConfigGlobalView({super.key});

  @override
  ConsumerState<ConfigGlobalView> createState() => _ConfigGlobalViewState();
}

class _ConfigGlobalViewState extends ConsumerState<ConfigGlobalView> {
  final _toleranciaController = TextEditingController(text: '5');
  final _precisionController = TextEditingController(text: '50');
  bool _requiereFoto = true;
  bool _requiereGeo = true;
  bool _mapaEnabled = true;
  bool _reportesEnabled = false;
  bool _pushEnabled = true;

  @override
  void dispose() {
    _toleranciaController.dispose();
    _precisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Global'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextosLegales(),
          _buildValoresPorDefecto(),
          _buildFeaturesGlobales(),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Guardar cambios',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración guardada')),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedDarkButton(
            text: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextosLegales() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Privacidad',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Textos legales',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Editar enlaces o textos de Términos y Condiciones y Política de Privacidad.',
              style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edición de textos disponible al conectar backend.'),
                    ),
                  );
                },
                child: const Text('Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValoresPorDefecto() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valores por defecto',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toleranciaController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Minutos de tolerancia'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precisionController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Precisión mínima GPS (metros)'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _requiereFoto,
              title: const Text('Requiere foto por defecto'),
              onChanged: (value) => setState(() => _requiereFoto = value),
            ),
            SwitchListTile(
              value: _requiereGeo,
              title: const Text('Requiere geolocalización por defecto'),
              onChanged: (value) => setState(() => _requiereGeo = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGlobales() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Features globales',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _mapaEnabled,
              title: const Text('Habilitar módulo de mapa de empleados'),
              onChanged: (value) => setState(() => _mapaEnabled = value),
            ),
            SwitchListTile(
              value: _reportesEnabled,
              title: const Text('Habilitar reportes avanzados'),
              onChanged: (value) => setState(() => _reportesEnabled = value),
            ),
            SwitchListTile(
              value: _pushEnabled,
              title: const Text('Habilitar notificaciones push globales'),
              onChanged: (value) => setState(() => _pushEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.primaryRed),
      ),
    );
  }
}


