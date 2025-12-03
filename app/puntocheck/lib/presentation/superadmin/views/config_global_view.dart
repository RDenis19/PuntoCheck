import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/global_settings.dart';
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
  GlobalSettings? _currentSettings;
  bool _isSaving = false;

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
      _currentSettings = data;
      _toleranciaController.text = '${data.toleranceMinutes}';
      _precisionController.text = '${data.geofenceRadius}';
      _requiereFoto = data.requirePhoto;
      _requiereGeo = data.geofenceRadius > 0;
      _senderController.text = data.senderEmail;
      _alertThresholdController.text = '${data.alertThreshold}';
      _domainController.text = data.adminAutoDomain ?? '';
      _trialOrgsController.text = '${data.trialMaxOrgs}';
      _trialDaysController.text = '${data.trialDays}';
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
              text: _isSaving ? 'Guardando...' : 'Guardar cambios',
              enabled: !_isSaving,
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 12),
            OutlinedDarkButton(
              text: 'Cerrar sesion',
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
              'Terminos y Privacidad',
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
              'Editar enlaces o textos de Terminos y Condiciones y Politica de Privacidad.',
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
                          Text('Edicion de textos disponible al conectar backend.'),
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
              decoration: _inputDecoration(
                label: 'Minutos de tolerancia',
                helper: 'Minutos extra antes de marcar tardanza.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precisionController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                label: 'Geocerca (metros)',
                helper: 'Radio sugerido 30-100m segun tu sitio.',
              ),
            ),
            const SizedBox(height: 12),
            _switchTile(
              value: _requiereFoto,
              title: 'Requiere foto en check-in',
              subtitle: 'Pide foto para validar identidad.',
              onChanged: (v) => _handleToggle(
                current: _requiereFoto,
                next: v,
                reason: 'Sin foto no podras auditar quien marco asistencia.',
                onAccept: () => setState(() => _requiereFoto = v),
              ),
            ),
            _switchTile(
              value: _requiereGeo,
              title: 'Requiere geolocalizacion',
              subtitle: 'Valida que el check-in ocurra dentro de la geocerca.',
              onChanged: (v) => _handleToggle(
                current: _requiereGeo,
                next: v,
                reason: 'Sin geolocalizacion no se detectara si el empleado esta fuera de zona.',
                onAccept: () => setState(() => _requiereGeo = v),
              ),
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
              decoration: _inputDecoration(
                label: 'Remitente email/SMS',
                helper: 'Ej: noreply@puntocheck.com o +593...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alertThresholdController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                label: 'Umbral de alertas',
                helper: 'Ej: 3 faltas seguidas activan alerta.',
              ),
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
              'Politicas de creacion de admins',
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
                label: 'Dominio permitido (opcional)',
                helper: 'Ej: empresa.com para auto-asignar admin',
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
              'Trial y limites globales',
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
                label: 'Maximo de organizaciones en trial (0 = ilimitado)',
                helper: 'Controla cuantos trials simultaneos permites.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trialDaysController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                label: 'Duracion del trial (dias)',
                helper: 'Periodo antes de pasar a plan pago.',
              ),
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
            _switchTile(
              value: _mapaEnabled,
              title: 'Mapa de empleados',
              subtitle: 'Ver posiciones en tiempo real.',
              onChanged: (v) => _handleToggle(
                current: _mapaEnabled,
                next: v,
                reason: 'Los admins no veran ubicaciones en el mapa.',
                onAccept: () => setState(() => _mapaEnabled = v),
              ),
            ),
            _switchTile(
              value: _reportesEnabled,
              title: 'Reportes avanzados',
              subtitle: 'KPIs historicos y exportables.',
              onChanged: (v) => _handleToggle(
                current: _reportesEnabled,
                next: v,
                reason: 'Se ocultaran modulos de reportes y exportacion.',
                onAccept: () => setState(() => _reportesEnabled = v),
              ),
            ),
            _switchTile(
              value: _pushEnabled,
              title: 'Notificaciones push globales',
              subtitle: 'Alertas en tiempo real a usuarios.',
              onChanged: (v) => _handleToggle(
                current: _pushEnabled,
                next: v,
                reason: 'Los usuarios dejaran de recibir alertas push.',
                onAccept: () => setState(() => _pushEnabled = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required bool value,
    required String title,
    String? subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
            )
          : null,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({required String label, String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
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

  Future<void> _handleToggle({
    required bool current,
    required bool next,
    required String reason,
    required VoidCallback onAccept,
  }) async {
    if (current && !next) {
      final ok = await _confirmDisable(reason);
      if (!ok) return;
    }
    onAccept();
  }

  Future<bool> _confirmDisable(String reason) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Estas seguro de desactivar?',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                reason,
                style: const TextStyle(color: AppColors.backgroundDark),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Desactivar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final controller = ref.read(globalSettingsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final tolerance = int.tryParse(_toleranciaController.text) ?? 5;
    final geofence = int.tryParse(_precisionController.text) ?? 50;
    final alertThreshold = int.tryParse(_alertThresholdController.text) ?? 3;
    final trialOrgs = int.tryParse(_trialOrgsController.text) ?? 0;
    final trialDays = int.tryParse(_trialDaysController.text) ?? 14;

    final baseSettings = _currentSettings ?? GlobalSettings.defaults();
    final updated = baseSettings.copyWith(
      toleranceMinutes: tolerance,
      geofenceRadius: geofence,
      requirePhoto: _requiereFoto,
      senderEmail: _senderController.text.trim(),
      alertThreshold: alertThreshold,
      adminAutoDomain: _domainController.text.trim(),
      trialMaxOrgs: trialOrgs,
      trialDays: trialDays,
    );

    await controller.save(updated);
    _currentSettings = updated;

    if (!mounted) return;
    final state = ref.read(globalSettingsControllerProvider);
    if (state.hasError) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error guardando: ${state.error}')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Configuracion guardada')),
      );
      ref.invalidate(globalSettingsProvider);
    }
    if (mounted) setState(() => _isSaving = false);
  }
}
