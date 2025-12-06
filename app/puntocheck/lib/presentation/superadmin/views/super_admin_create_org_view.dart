import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/planes_suscripcion.dart';
import 'package:puntocheck/presentation/shared/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Formulario para crear organización y asignar admin.
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
      appBar: AppBar(
        title: const Text('Crear organización'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _LabeledField(
                label: 'RUC',
                controller: _rucCtrl,
                validator: (v) => v == null || v.isEmpty ? 'Ingresa RUC' : null,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Razón social',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa razón social' : null,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Logo (URL opcional)',
                controller: _logoCtrl,
              ),
              const SizedBox(height: 12),
              const Text(
                'Plan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 6),
              plansAsync.when(
                data: (plans) => DropdownButtonFormField<PlanesSuscripcion>(
                  value: _selectedPlan,
                  items: plans
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.nombre} - \$${p.precioMensual}'),
                        ),
                      )
                      .toList(),
                  onChanged: isSaving
                      ? null
                      : (p) => setState(() => _selectedPlan = p),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.neutral100,
                  ),
                  validator: (v) => v == null ? 'Selecciona un plan' : null,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text(
                  'Error cargando planes: $e',
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSaving ? null : onSubmit,
                child: Text(isSaving ? 'Guardando...' : 'Crear organización'),
              ),
            ],
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
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryRed),
            ),
          ),
        ),
      ],
    );
  }
}
