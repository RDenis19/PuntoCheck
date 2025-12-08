import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/sucursal_geo_extension.dart';

class OrgAdminBranchesMapView extends ConsumerWidget {
  const OrgAdminBranchesMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(_branchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de sucursales'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_branchesProvider),
          ),
        ],
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(
              child: Text('No hay sucursales para mostrar'),
            );
          }

          final initial = _firstWithCoords(branches) ??
              const LatLng(-4.0033, -79.2030);

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
                      snippet: b.direccion ?? '',
                    ),
                    onTap: () {},
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
        error: (e, _) => Center(
          child: Text('Error cargando sucursales: $e'),
        ),
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
}

final _branchesProvider = FutureProvider.autoDispose<List<Sucursales>>((ref) async {
  return ref.read(organizationServiceProvider).getBranchesRls();
});
