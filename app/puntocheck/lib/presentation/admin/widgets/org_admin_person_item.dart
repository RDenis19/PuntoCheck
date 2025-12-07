import 'package:flutter/material.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

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
      subtitle: Text(
        perfil.rol?.value ?? 'Sin rol',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.neutral700,
        ),
      ),
      trailing: Chip(
        backgroundColor:
            active ? AppColors.successGreen.withValues(alpha: 0.12) : AppColors.neutral200,
        label: Text(
          active ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: active ? AppColors.successGreen : AppColors.neutral600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
