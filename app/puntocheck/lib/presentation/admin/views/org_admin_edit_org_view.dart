import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminEditOrgView extends ConsumerStatefulWidget {
  const OrgAdminEditOrgView({super.key});

  @override
  ConsumerState<OrgAdminEditOrgView> createState() => _OrgAdminEditOrgViewState();
}

class _OrgAdminEditOrgViewState extends ConsumerState<OrgAdminEditOrgView> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(orgAdminOrganizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar organización')),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (org) {
          final nameCtrl = TextEditingController(text: org.razonSocial);
          final logoCtrl = TextEditingController(text: org.logoUrl ?? '');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Razón social'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: logoCtrl,
                    decoration: const InputDecoration(labelText: 'Logo URL'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                      razonSocial: nameCtrl.text.trim(),
                                      logoUrl: logoCtrl.text.trim().isEmpty
                                          ? null
                                          : logoCtrl.text.trim(),
                                    );
                                ref.invalidate(orgAdminOrganizationProvider);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Organización actualizada'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
