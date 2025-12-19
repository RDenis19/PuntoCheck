import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class _BranchesMapData {
  const _BranchesMapData({
    required this.branches,
    required this.managersByBranchId,
  });

  final List<Sucursales> branches;
  final Map<String, List<Perfiles>> managersByBranchId;
}

final _branchesMapDataProvider = FutureProvider.autoDispose<_BranchesMapData>((
  ref,
) async {
  final branches = await ref.watch(orgAdminBranchesProvider.future);
  final branchIds = branches.map((b) => b.id).toList(growable: false);

  final assignments = await ref
      .read(staffServiceProvider)
      .getBranchManagersForBranches(branchIds);

  final Map<String, List<Perfiles>> managersByBranchId = {};
  for (final a in assignments) {
    final perfil = a.managerProfile;
    if (perfil == null) continue;
    managersByBranchId.putIfAbsent(a.sucursalId, () => []).add(perfil);
  }

  return _BranchesMapData(
    branches: branches,
    managersByBranchId: managersByBranchId,
  );
});

class OrgAdminBranchesMapView extends ConsumerWidget {
  const OrgAdminBranchesMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(_branchesMapDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de sucursales'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_branchesMapDataProvider),
          ),
        ],
      ),
      body: branchesAsync.when(
        data: (data) {
          final branches = data.branches;
          if (branches.isEmpty) {
            return const Center(child: Text('No hay sucursales para mostrar'));
          }

          final initial =
              _firstWithCoords(branches) ?? const LatLng(-4.0033, -79.2030);

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            markers: branches
                .where((b) => b.centerLatLng != null)
                .map(
                  (b) => Marker(
                    markerId: MarkerId(b.id),
                    position: b.centerLatLng!,
                    infoWindow: InfoWindow(
                      title: b.nombre,
                      snippet: _snippetForBranch(
                        b,
                        data.managersByBranchId[b.id] ?? const [],
                      ),
                    ),
                    onTap: () => _showBranchDetailsSheet(
                      context,
                      branch: b,
                      managers: data.managersByBranchId[b.id] ?? const [],
                    ),
                  ),
                )
                .toSet(),
            circles: branches
                .where((b) => b.centerLatLng != null)
                .map(
                  (b) => Circle(
                    circleId: CircleId('c_${b.id}'),
                    center: b.centerLatLng!,
                    radius: (b.radioMetros ?? 100).toDouble(),
                    strokeColor: AppColors.primaryRed.withValues(alpha: 0.4),
                    fillColor: AppColors.primaryRed.withValues(alpha: 0.12),
                    strokeWidth: 2,
                  ),
                )
                .toSet(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando sucursales: $e')),
      ),
    );
  }

  LatLng? _firstWithCoords(List<Sucursales> branches) {
    for (final b in branches) {
      final c = b.centerLatLng;
      if (c != null) return c;
    }
    return null;
  }

  static String _snippetForBranch(Sucursales branch, List<Perfiles> managers) {
    final address = branch.direccion?.trim();
    final managerNames = managers.map((m) => m.nombreCompleto).toList();

    final parts = <String>[];
    if (address != null && address.isNotEmpty) parts.add(address);
    if (managerNames.isNotEmpty) {
      parts.add(
        managerNames.length == 1
            ? 'Encargado: ${managerNames.first}'
            : 'Encargados: ${managerNames.join(', ')}',
      );
    }
    return parts.join(' • ');
  }

  static void _showBranchDetailsSheet(
    BuildContext context, {
    required Sucursales branch,
    required List<Perfiles> managers,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  branch.direccion?.trim().isNotEmpty == true
                      ? branch.direccion!.trim()
                      : 'Sin direccion',
                  style: const TextStyle(color: AppColors.neutral700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Radio: ${(branch.radioMetros ?? 50)} m',
                  style: const TextStyle(color: AppColors.neutral700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Encargados',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                if (managers.isEmpty)
                  const Text(
                    'Sin encargados asignados.',
                    style: TextStyle(color: AppColors.neutral700),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: managers
                        .map(
                          (m) => Chip(
                            label: Text(m.nombreCompleto),
                            side: const BorderSide(color: AppColors.neutral200),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
