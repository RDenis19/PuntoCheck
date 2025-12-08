import 'package:flutter/material.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/common/widgets/status_chip.dart';

class OrgAdminPersonItem extends StatelessWidget {
  final Perfiles perfil;
  final VoidCallback? onTap;

  const OrgAdminPersonItem({
    super.key,
    required this.perfil,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials =
        '${perfil.nombres.isNotEmpty ? perfil.nombres[0] : ''}${perfil.apellidos.isNotEmpty ? perfil.apellidos[0] : ''}'
            .toUpperCase();
    final active = perfil.activo != false;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
        child: Text(
          initials.isNotEmpty ? initials : '?',
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        '${perfil.nombres} ${perfil.apellidos}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            perfil.rol?.value ?? 'Sin rol',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.neutral700,
            ),
          ),
          if (perfil.cargo != null && perfil.cargo!.isNotEmpty)
            Text(
              perfil.cargo!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.neutral600,
              ),
            ),
        ],
      ),
      trailing: StatusChip(
        label: active ? 'Activo' : 'Inactivo',
        isPositive: active,
      ),
    );
  }
}
