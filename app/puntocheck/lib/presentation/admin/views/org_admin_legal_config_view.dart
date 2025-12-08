import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminLegalConfigView extends ConsumerStatefulWidget {
  const OrgAdminLegalConfigView({super.key});

  @override
  ConsumerState<OrgAdminLegalConfigView> createState() => _OrgAdminLegalConfigViewState();
}

class _OrgAdminLegalConfigViewState extends ConsumerState<OrgAdminLegalConfigView> {
  final _formKey = GlobalKey<FormState>();
  final _toleranciaCtrl = TextEditingController();
  final _descansoCtrl = TextEditingController();
  final _maxExtrasCtrl = TextEditingController();
  final _inicioNocturnaCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _toleranciaCtrl.dispose();
    _descansoCtrl.dispose();
    _maxExtrasCtrl.dispose();
    _inicioNocturnaCtrl.dispose();
    super.dispose();
  }

  void _seed(Organizaciones org) {
    final cfg = org.configuracionLegal ?? {};
    _toleranciaCtrl.text = '${cfg['tolerancia_entrada_min'] ?? 15}';
    _descansoCtrl.text = '${cfg['tiempo_descanso_min'] ?? 60}';
    _maxExtrasCtrl.text = '${cfg['max_horas_extras_dia'] ?? 4}';
    _inicioNocturnaCtrl.text = cfg['inicio_jornada_nocturna']?.toString() ?? '22:00';
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(orgAdminOrganizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración legal'),
      ),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (org) {
          _seed(org);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajusta la configuración legal de tu organización',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _NumberField(
                      controller: _toleranciaCtrl,
                      label: 'Tolerancia de entrada (minutos)',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _descansoCtrl,
                      label: 'Tiempo de descanso (minutos)',
                      icon: Icons.snooze_outlined,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _maxExtrasCtrl,
                      label: 'Máx. horas extra por día',
                      icon: Icons.more_time_outlined,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inicioNocturnaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Inicio jornada nocturna (HH:mm)',
                        prefixIcon: Icon(Icons.nights_stay_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                        onPressed: _saving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _saving = true);
                                try {
                                  final config = {
                                    'tolerancia_entrada_min':
                                        int.tryParse(_toleranciaCtrl.text.trim()) ?? 0,
                                    'tiempo_descanso_min':
                                        int.tryParse(_descansoCtrl.text.trim()) ?? 0,
                                    'max_horas_extras_dia':
                                        int.tryParse(_maxExtrasCtrl.text.trim()) ?? 0,
                                    'inicio_jornada_nocturna':
                                        _inicioNocturnaCtrl.text.trim(),
                                  };
                                  await ref
                                      .read(organizationServiceProvider)
                                      .updateLegalConfig(org.id, config);
                                  ref.invalidate(orgAdminOrganizationProvider);
                                  if (!mounted) return;
                                  showAppSnackBar(context, 'Configuración actualizada');
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  if (!mounted) return;
                                  showAppSnackBar(
                                    context,
                                    'Error: $e',
                                    success: false,
                                  );
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
    );
  }
}
