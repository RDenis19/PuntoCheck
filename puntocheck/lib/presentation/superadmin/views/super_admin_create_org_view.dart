import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/planes_suscripcion.dart';
import 'package:puntocheck/presentation/shared/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminCreateOrgView extends ConsumerStatefulWidget {
  const SuperAdminCreateOrgView({super.key});

  @override
  ConsumerState<SuperAdminCreateOrgView> createState() =>
      _SuperAdminCreateOrgViewState();
}

class _SuperAdminCreateOrgViewState
    extends ConsumerState<SuperAdminCreateOrgView> {
  final _formKey = GlobalKey<FormState>();
  final _rucCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  PlanesSuscripcion? _selectedPlan;

  @override
  void dispose() {
    _rucCtrl.dispose();
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final creationState = ref.watch(organizationCreationControllerProvider);
    final isSaving = creationState.isLoading;

    Future<void> onSubmit() async {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedPlan == null) {
        showAppSnack(context, 'Selecciona un plan', isError: true);
        return;
      }

      final ruc = _rucCtrl.text.trim();
      final rucValid = RegExp(r'^[0-9]{10,13}$').hasMatch(ruc);
      if (!rucValid) {
        showAppSnack(
          context,
          'RUC inválido, revisa el formato.',
          isError: true,
        );
        return;
      }

      await ref
          .read(organizationCreationControllerProvider.notifier)
          .createOrganizationWithAdmin(
            ruc: ruc,
            razonSocial: _nameCtrl.text.trim(),
            planId: _selectedPlan!.id,
            logoUrl: _logoCtrl.text.trim().isEmpty
                ? null
                : _logoCtrl.text.trim(),
          );

      final state = ref.read(organizationCreationControllerProvider);
      if (!mounted) return;
      if (state.hasError) {
        showAppSnack(context, 'Error: ${state.error}', isError: true);
      } else {
        showAppSnack(context, 'Organización creada');
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FB,
      ), // Fondo neutro suave como en las capturas
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Crear organización',
          style: TextStyle(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.neutral700),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card contenedor para agrupar los campos
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: 'RUC',
                        controller: _rucCtrl,
                        hintText: 'Ej: 1790012345001',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingresa RUC' : null,
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Razón social',
                        controller: _nameCtrl,
                        hintText: 'Nombre oficial de la empresa',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Ingresa razón social'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Logo (URL opcional)',
                        controller: _logoCtrl,
                        hintText: 'https://imagen.com/logo.png',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Plan de suscripción',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      plansAsync.when(
                        data: (plans) =>
                            DropdownButtonFormField<PlanesSuscripcion>(
                              initialValue: _selectedPlan,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.neutral700,
                              ),
                              items: plans
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        '${p.nombre} - \$${p.precioMensual}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (p) => setState(() => _selectedPlan = p),
                              decoration: _inputDecoration(
                                hint: 'Selecciona un plan',
                              ),
                              validator: (v) =>
                                  v == null ? 'Selecciona un plan' : null,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                        loading: () => const LinearProgressIndicator(
                          backgroundColor: AppColors.neutral100,
                          color: AppColors.primaryRed,
                        ),
                        error: (e, _) => Text(
                          'Error cargando planes',
                          style: TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Botón principal
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primaryRed.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isSaving ? null : onSubmit,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear organización',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final String? hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDecoration(hint: hintText),
        ),
      ],
    );
  }
}

// Decoración global para consistencia visual
InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.neutral500,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    filled: true,
    fillColor: const Color(
      0xFFF3F5F7,
    ), // Gris muy suave para el fondo del campo
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE7ECF3), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
    ),
  );
}
