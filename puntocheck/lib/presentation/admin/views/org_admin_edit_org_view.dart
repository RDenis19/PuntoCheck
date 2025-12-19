import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminEditOrgView extends ConsumerStatefulWidget {
  const OrgAdminEditOrgView({super.key});

  @override
  ConsumerState<OrgAdminEditOrgView> createState() => _OrgAdminEditOrgViewState();
}

class _OrgAdminEditOrgViewState extends ConsumerState<OrgAdminEditOrgView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  bool _saving = false;
  String? _orgId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rucCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  void _setInitialValues(Organizaciones org) {
    if (_orgId == org.id) return;
    _orgId = org.id;
    _nameCtrl.text = org.razonSocial;
    _rucCtrl.text = org.ruc;
    _logoCtrl.text = org.logoUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(orgAdminOrganizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar organización')),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (org) {
          _setInitialValues(org);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edita su organización',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Razón social',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rucCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'RUC',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _logoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Logo URL',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
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
                        label:
                            Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                        onPressed: _saving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _saving = true);
                                try {
                                   await ref
                                       .read(organizationServiceProvider)
                                       .updateOrganization(
                                         orgId: org.id,
                                         razonSocial: _nameCtrl.text.trim(),
                                         logoUrl: _logoCtrl.text.trim().isEmpty
                                             ? null
                                             : _logoCtrl.text.trim(),
                                       );
                                   ref.invalidate(orgAdminOrganizationProvider);
                                   if (!context.mounted) return;
                                   showAppSnackBar(
                                     context,
                                     'Organización actualizada',
                                   );
                                   Navigator.of(context).pop();
                                 } catch (e) {
                                   if (!context.mounted) return;
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
