import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
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
  final _senderController = TextEditingController();
  final _alertThresholdController = TextEditingController(text: '3');
  final _domainController = TextEditingController();
  final _trialOrgsController = TextEditingController(text: '0');
  final _trialDaysController = TextEditingController(text: '14');
  bool _requiereFoto = true;
  bool _requiereGeo = true;
  bool _mapaEnabled = true;
  bool _reportesEnabled = false;
  bool _pushEnabled = true;
  bool _initialized = false;

  @override
  void dispose() {
    _toleranciaController.dispose();
    _precisionController.dispose();
    _senderController.dispose();
    _alertThresholdController.dispose();
    _domainController.dispose();
    _trialOrgsController.dispose();
    _trialDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(globalSettingsProvider);
    settingsAsync.whenData((data) {
      if (_initialized) return;
      _initialized = true;
      _toleranciaController.text =
          '${data['tolerance_minutes'] ?? _toleranciaController.text}';
      _precisionController.text =
          '${data['geofence_radius'] ?? _precisionController.text}';
      _requiereFoto = data['require_photo'] as bool? ?? _requiereFoto;
      _requiereGeo = (data['geofence_radius'] as int? ?? 0) > 0;
      _senderController.text = data['sender_email'] as String? ?? '';
      _alertThresholdController.text =
          '${data['alert_threshold'] ?? _alertThresholdController.text}';
      _domainController.text = data['admin_auto_domain'] as String? ?? '';
      _trialOrgsController.text =
          '${data['trial_max_orgs'] ?? _trialOrgsController.text}';
      _trialDaysController.text =
          '${data['trial_days'] ?? _trialDaysController.text}';
      setState(() {});
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Global'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: settingsAsync.when(
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextosLegales(),
            _buildValoresPorDefecto(),
            _buildNotificaciones(),
            _buildAdminPolicies(),
            _buildTrialConfig(),
            _buildFeaturesGlobales(),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Guardar cambios',
              onPressed: _saveSettings,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error cargando configuración: $err',
            style: const TextStyle(color: AppColors.primaryRed),
          ),
        ),
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
                      content:
                          Text('Edición de textos disponible al conectar backend.'),
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
              decoration: _inputDecoration('Minutos de tolerancia (default)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precisionController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Geocerca por defecto (metros)'),
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

  Widget _buildNotificaciones() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notificaciones',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderController,
              decoration: _inputDecoration('Remitente email/SMS'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alertThresholdController,
              keyboardType: TextInputType.number,
              decoration:
                  _inputDecoration('Umbral de alertas (ej. 3 faltas seguidas)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPolicies() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Políticas de creación de admins',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _domainController,
              decoration: _inputDecoration(
                'Dominio permitido para auto-asignar admin (opcional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialConfig() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trial y límites globales',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trialOrgsController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Máximo de organizaciones en modo prueba (0 = ilimitado)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trialDaysController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Duración del trial (días)'),
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

  Future<void> _saveSettings() async {
    final controller = ref.read(globalSettingsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final tolerance = int.tryParse(_toleranciaController.text) ?? 5;
    final geofence = int.tryParse(_precisionController.text) ?? 50;
    final alertThreshold = int.tryParse(_alertThresholdController.text) ?? 3;
    final trialOrgs = int.tryParse(_trialOrgsController.text) ?? 0;
    final trialDays = int.tryParse(_trialDaysController.text) ?? 14;

    await controller.save({
      'tolerance_minutes': tolerance,
      'geofence_radius': geofence,
      'require_photo': _requiereFoto,
      'sender_email': _senderController.text.trim(),
      'alert_threshold': alertThreshold,
      'admin_auto_domain': _domainController.text.trim(),
      'trial_max_orgs': trialOrgs,
      'trial_days': trialDays,
    });

    if (!mounted) return;
    final state = ref.read(globalSettingsControllerProvider);
    if (state.hasError) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error guardando: ${state.error}')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
      ref.invalidate(globalSettingsProvider);
    }
  }
}
