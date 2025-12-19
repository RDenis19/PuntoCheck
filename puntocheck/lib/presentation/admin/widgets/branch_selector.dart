import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Selector dropdown de sucursal para filtros
class BranchSelector extends ConsumerWidget {
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool showAllOption;

  const BranchSelector({
    super.key,
    this.selectedBranchId,
    required this.onChanged,
    this.label,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(_branchesProvider);

    return branchesAsync.when(
      data: (branches) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutral300, width: 1.5),
              ),
              child: DropdownButtonFormField<String?>(
                key: ValueKey(selectedBranchId),
                initialValue: selectedBranchId,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.store_mall_directory_outlined, color: AppColors.neutral600),
                ),
                hint: const Text('Seleccionar sucursal'),
                isExpanded: true,
                items: [
                  if (showAllOption)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las sucursales'),
                    ),
                  ...branches.map((branch) {
                    return DropdownMenuItem<String?>(
                      value: branch.id,
                      child: Text(
                        branch.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error cargando sucursales: $e',
          style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
        ),
      ),
    );
  }
}

// Provider para obtener sucursales
final _branchesProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final orgId = profile?.organizacionId;
  if (orgId == null) throw Exception('No org ID');
  return ref.read(organizationServiceProvider).getBranches(orgId);
});
