import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminBranchesView extends ConsumerStatefulWidget {
  const OrgAdminBranchesView({super.key});

  @override
  ConsumerState<OrgAdminBranchesView> createState() => _OrgAdminBranchesViewState();
}

class _OrgAdminBranchesViewState extends ConsumerState<OrgAdminBranchesView> {
  late Future<List<Sucursales>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Sucursales>> _load() async {
    final org = await ref.read(orgAdminOrganizationProvider.future);
    return ref.read(organizationServiceProvider).getBranches(org.id);
  }

  Future<void> _createBranch() async {
    final org = await ref.read(orgAdminOrganizationProvider.future);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '100');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva sucursal'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.store_mall_directory_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          prefixIcon: Icon(Icons.my_location_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: lonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          prefixIcon: Icon(Icons.my_location_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: radiusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Radio geocerca (m)',
                    prefixIcon: Icon(Icons.radio_button_checked),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!formKey.currentState!.validate()) return;

    final lat = double.tryParse(latCtrl.text);
    final lon = double.tryParse(lonCtrl.text);
    final radius = int.tryParse(radiusCtrl.text);

    try {
      final branch = Sucursales(
        id: '',
        organizacionId: org.id,
        nombre: nameCtrl.text.trim(),
        direccion: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        ubicacionCentral: (lat != null && lon != null)
            ? {
                'type': 'Point',
                'coordinates': [lon, lat],
              }
            : null,
        radioGeocercaMetros: radius,
        tieneQrHabilitado: true,
      );
      await ref.read(organizationServiceProvider).createBranch(branch);
      setState(() => _future = _load());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sucursal creada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sucursales')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBranch,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<Sucursales>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const _EmptyState(
              icon: Icons.store_mall_directory_outlined,
              text: 'No hay sucursales registradas.',
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = data[index];
              return ListTile(
                title: Text(s.nombre),
                subtitle: Text(s.direccion ?? 'Sin dirección'),
                trailing: Chip(
                  label: Text(
                    (s.tieneQrHabilitado ?? false) ? 'QR activo' : 'QR apagado',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.neutral500),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
