import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_branch_form.dart';
import 'package:puntocheck/presentation/common/widgets/confirm_dialog.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_location_picker_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_qr_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminBranchDetailView extends ConsumerStatefulWidget {
  final Sucursales branch;

  const OrgAdminBranchDetailView({super.key, required this.branch});

  @override
  ConsumerState<OrgAdminBranchDetailView> createState() =>
      _OrgAdminBranchDetailViewState();
}

class _OrgAdminBranchDetailViewState
    extends ConsumerState<OrgAdminBranchDetailView> {
  bool _isSaving = false;
  late Sucursales _editableBranch;

  @override
  void initState() {
    super.initState();
    _editableBranch = widget.branch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de sucursal'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (_editableBranch.tieneQrHabilitado == true)
            IconButton(
              icon: const Icon(Icons.qr_code_2_outlined),
              tooltip: 'Ver QR',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrgAdminBranchQrView(branch: _editableBranch),
                  ),
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteBranch();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                  title: Text('Eliminar sucursal'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _MapPreview(
                branch: _editableBranch,
                onEdit: () async {
                  final coords = _editableBranch.centerLatLng;
                  // Si no hay coordenadas válidas, evita mostrar mapa vacío en el picker
                  final initialPos = coords ?? const LatLng(-4.0033, -79.2030);
                  final result = await Navigator.of(context)
                      .push<BranchLocationResult>(
                        MaterialPageRoute(
                          builder: (_) => OrgAdminBranchLocationPickerView(
                            initialPosition: initialPos,
                            initialRadius: (_editableBranch.radioMetros ?? 100)
                                .toDouble(),
                          ),
                        ),
                      );
                  if (result != null) {
                    setState(() {
                      _editableBranch = _editableBranch.copyWith(
                        ubicacionCentral: {
                          'type': 'Point',
                          'coordinates': [
                            result.position.longitude,
                            result.position.latitude,
                          ],
                        },
                        radioMetros: result.radius.toInt(),
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              _CoordsRow(branch: _editableBranch),
              const SizedBox(height: 12),
              _BranchManagersSection(branch: _editableBranch),
              const SizedBox(height: 12),
              OrgAdminBranchForm(
                key: ValueKey(_editableBranch.ubicacionCentral.toString()),
                initial: _editableBranch,
                isSaving: _isSaving,
                onSubmit: (branch) async {
                  setState(() => _isSaving = true);
                  try {
                    await ref
                        .read(orgAdminBranchMutationControllerProvider.notifier)
                        .updateBranch(branch);
                    final state = ref.read(
                      orgAdminBranchMutationControllerProvider,
                    );
                    if (state.hasError) throw state.error!;
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (!mounted) return;
                    final msg = e.toString();
                    final friendly = msg.contains('No tienes permisos')
                        ? 'No tienes permisos para editar sucursales. Revisa las policies RLS.'
                        : msg;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(friendly)));
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBranch() async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Eliminar sucursal',
      message:
          'Esta accion marcara la sucursal como eliminada (soft delete). Los registros historicos se mantienen.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (!confirm || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(orgAdminBranchMutationControllerProvider.notifier)
          .delete(widget.branch.id);
      final state = ref.read(orgAdminBranchMutationControllerProvider);
      if (state.hasError) throw state.error!;

      if (!mounted) return;
      showAppSnackBar(context, 'Sucursal eliminada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MapPreview extends StatelessWidget {
  final Sucursales branch;
  final VoidCallback onEdit;

  const _MapPreview({required this.branch, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final center = branch.centerLatLng ?? const LatLng(-4.0033, -79.2030);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 16),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('branch'),
                  position: center,
                  infoWindow: InfoWindow(title: branch.nombre),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('radius'),
                  center: center,
                  radius: (branch.radioMetros ?? 100).toDouble(),
                  strokeColor: AppColors.primaryRed.withValues(alpha: 0.5),
                  fillColor: AppColors.primaryRed.withValues(alpha: 0.16),
                  strokeWidth: 2,
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    branch.direccion ?? 'Sin direccion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordsRow extends StatelessWidget {
  final Sucursales branch;

  const _CoordsRow({required this.branch});

  @override
  Widget build(BuildContext context) {
    final center =
        branch.centerLatLng ??
        const LatLng(-4.0033, -79.2030); // fallback mostrado en mapa
    final lat = center.latitude;
    final lon = center.longitude;
    return Row(
      children: [
        Expanded(child: _badge('Latitud', lat.toStringAsFixed(6))),
        const SizedBox(width: 8),
        Expanded(child: _badge('Longitud', lon.toStringAsFixed(6))),
      ],
    );
  }

  Widget _badge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Encargados de sucursal
// ---------------------------------------------------------------------------
class _BranchManagersSection extends ConsumerStatefulWidget {
  final Sucursales branch;

  const _BranchManagersSection({required this.branch});

  @override
  ConsumerState<_BranchManagersSection> createState() =>
      _BranchManagersSectionState();
}

class _BranchManagersSectionState
    extends ConsumerState<_BranchManagersSection> {
  bool _processing = false;

  Future<void> _addManager(BuildContext context) async {
    setState(() => _processing = true);
    try {
      final managers = await ref.read(orgAdminManagersProvider.future);
      final assigned = await ref.read(
        orgAdminBranchManagersProvider(widget.branch.id).future,
      );
      final assignedIds = assigned.map((e) => e.managerId).toSet();

      final available = managers
          .where((m) => !assignedIds.contains(m.id))
          .toList();

      if (available.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay managers disponibles para asignar.'),
          ),
        );
        return;
      }

      final selected = await showDialog<Perfiles>(
        context: context,
        builder: (_) => _ManagerPickerDialog(managers: available),
      );
      if (selected == null) return;

      await ref
          .read(staffServiceProvider)
          .assignBranchManager(
            branchId: widget.branch.id,
            managerId: selected.id,
          );
      ref.invalidate(orgAdminBranchManagersProvider(widget.branch.id));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error asignando encargado: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _removeManager(BuildContext context, String assignmentId) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(staffServiceProvider)
          .deactivateBranchManager(assignmentId);
      ref.invalidate(orgAdminBranchManagersProvider(widget.branch.id));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error quitando encargado: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managersAsync = ref.watch(
      orgAdminBranchManagersProvider(widget.branch.id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Encargados de la sucursal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _processing ? null : () => _addManager(context),
              icon: const Icon(Icons.add, color: AppColors.primaryRed),
              label: const Text(
                'Agregar',
                style: TextStyle(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: managersAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Text(
                  'Sin encargados asignados.',
                  style: TextStyle(color: AppColors.neutral700),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((item) {
                  final perfil = item.managerProfile;
                  final label = perfil != null
                      ? '${perfil.nombres} ${perfil.apellidos}'
                      : item.managerId;
                  return InputChip(
                    label: Text(label),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _processing
                        ? null
                        : () => _removeManager(context, item.id),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'No se pudieron cargar encargados: $e',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagerPickerDialog extends StatefulWidget {
  const _ManagerPickerDialog({required this.managers});

  final List<Perfiles> managers;

  @override
  State<_ManagerPickerDialog> createState() => _ManagerPickerDialogState();
}

class _ManagerPickerDialogState extends State<_ManagerPickerDialog> {
  Perfiles? selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar manager'),
      content: DropdownButtonFormField<Perfiles>(
        value: selected,
        items: widget.managers
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text('${m.nombres} ${m.apellidos}'),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => selected = value),
        decoration: const InputDecoration(
          labelText: 'Manager',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
