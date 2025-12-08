import 'package:flutter/material.dart';
import 'package:puntocheck/models/sucursales.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/common/widgets/status_chip.dart';

class OrgAdminBranchItem extends StatelessWidget {
  final Sucursales branch;
  final VoidCallback? onTap;

  const OrgAdminBranchItem({
    super.key,
    required this.branch,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_mall_directory, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    branch.direccion ?? 'Sin direccion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Radio: ${branch.radioMetros ?? 0}m',
                    style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (branch.tieneQrHabilitado == true)
              const StatusChip(label: 'QR activo', isPositive: true),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutral500),
          ],
        ),
      ),
    );
  }
}

