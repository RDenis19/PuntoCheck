import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/encargados_sucursales.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/presentation/admin/widgets/org_admin_branch_form.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_location_picker_view.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_branch_qr_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

final _branchManagersProvider =
    FutureProvider.family<List<EncargadosSucursales>, String>((ref, branchId) {
      return ref.watch(staffServiceProvider).getBranchManagers(branchId);
    });
final _branchStaffProvider =
    FutureProvider.family<List<Perfiles>, String>((ref, orgId) {
      return ref.watch(staffServiceProvider).getStaff(orgId);
    });

class OrgAdminBranchDetailView extends ConsumerStatefulWidget {
  final Sucursales branch;

  const OrgAdminBranchDetailView({super.key, required this.branch});

  @override
  ConsumerState<OrgAdminBranchDetailView> createState() => _OrgAdminBranchDetailViewState();
}

class _OrgAdminBranchDetailViewState extends ConsumerState<OrgAdminBranchDetailView> {
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
                    builder: (_) => OrgAdminBranchQrView(branch: _editableBranch),
                  ),
                );
              },
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
                  final result = await Navigator.of(context).push<BranchLocationResult>(
                    MaterialPageRoute(
                      builder: (_) => OrgAdminBranchLocationPickerView(
                        initialPosition: initialPos,
                        initialRadius: (_editableBranch.radioMetros ?? 100).toDouble(),
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _editableBranch = _editableBranch.copyWith(
                        ubicacionCentral: {
                          'type': 'Point',
                          'coordinates': [result.position.longitude, result.position.latitude],
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
                    await ref.read(organizationServiceProvider).updateBranch(
                          branchId: widget.branch.id,
                          nombre: branch.nombre,
                          direccion: branch.direccion,
                          radioMetros: branch.radioMetros,
                          lat: _extractLat(branch.ubicacionCentral),
                          lon: _extractLon(branch.ubicacionCentral),
                          tieneQrHabilitado: branch.tieneQrHabilitado,
                        );
                    if (!mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (!mounted) return;
                    final msg = e.toString();
                    final friendly = msg.contains('No tienes permisos')
                        ? 'No tienes permisos para editar sucursales. Revisa las policies RLS.'
                        : msg;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendly)),
                    );
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

  double? _extractLat(dynamic geo) {
    final coords = _coordsFromGeo(geo);
    return coords?[1];
  }

  double? _extractLon(dynamic geo) {
    final coords = _coordsFromGeo(geo);
    return coords?[0];
  }

  List<double>? _coordsFromGeo(dynamic geo) {
    if (geo is Map && geo['coordinates'] is List) {
      final coords = geo['coordinates'] as List;
      if (coords.length == 2) {
        final lon = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lon != null && lat != null) {
          return [lon, lat];
        }
      }
    }
    if (geo is List && geo.length == 2) {
      final lon = (geo[0] as num?)?.toDouble();
      final lat = (geo[1] as num?)?.toDouble();
      if (lon != null && lat != null) return [lon, lat];
    }
    if (geo is String && geo.contains('POINT')) {
      final start = geo.indexOf('(');
      final end = geo.indexOf(')');
      if (start != -1 && end != -1 && end > start + 1) {
        final parts = geo.substring(start + 1, end).split(' ');
        if (parts.length == 2) {
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lon != null && lat != null) {
            return [lon, lat];
          }
        }
      }
    }
    return null;
  }
}

class _MapPreview extends StatelessWidget {
  final Sucursales branch;
  final VoidCallback onEdit;

  const _MapPreview({
    required this.branch,
    required this.onEdit,
  });

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
                const Icon(Icons.location_on_outlined, color: AppColors.primaryRed),
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
        branch.centerLatLng ?? const LatLng(-4.0033, -79.2030); // fallback mostrado en mapa
    final lat = center.latitude;
    final lon = center.longitude;
    return Row(
      children: [
        Expanded(
          child: _badge('Latitud', lat?.toStringAsFixed(6) ?? '--'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _badge('Longitud', lon?.toStringAsFixed(6) ?? '--'),
        ),
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
          Text(label, style: const TextStyle(color: AppColors.neutral600, fontSize: 12)),
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
      final staff = await ref
          .read(staffServiceProvider)
          .getStaff(widget.branch.organizacionId);
      final managers =
          staff.where((p) => p.rol == RolUsuario.manager).toList();

      final assigned = await ref
          .read(staffServiceProvider)
          .getBranchManagers(widget.branch.id);
      final assignedIds = assigned.map((e) => e.managerId).toSet();

      final available =
          managers.where((m) => !assignedIds.contains(m.id)).toList();

      final selected = await showDialog<Perfiles>(
        context: context,
        builder: (_) => _ManagerPickerDialog(managers: available),
      );
      if (selected == null) return;

      await ref.read(staffServiceProvider).assignBranchManager(
            branchId: widget.branch.id,
            managerId: selected.id,
          );
      ref.invalidate(_branchManagersProvider(widget.branch.id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error asignando encargado: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _removeManager(
    BuildContext context,
    String assignmentId,
  ) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(staffServiceProvider)
          .deactivateBranchManager(assignmentId);
      ref.invalidate(_branchManagersProvider(widget.branch.id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error quitando encargado: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managersAsync = ref.watch(_branchManagersProvider(widget.branch.id));
    final staffAsync = ref.watch(_branchStaffProvider(widget.branch.organizacionId));
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
              return staffAsync.when(
                data: (staff) {
                  final staffMap = {
                    for (final p in staff) p.id: p,
                  };
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
                      final perfil =
                          item.managerProfile ?? staffMap[item.managerId];
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
