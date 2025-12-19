import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    super.key,
    required this.organization,
    this.planName,
    this.onTap,
  });

  final Organizaciones organization;
  final String? planName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(organization.estadoSuscripcion);
    final created =
        organization.creadoEn?.toIso8601String().split('T').first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF5)),
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
            _LogoBadge(
              logoUrl: organization.logoUrl,
              fallback: organization.razonSocial.isNotEmpty
                  ? organization.razonSocial[0].toUpperCase()
                  : '?',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.razonSocial,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planName ?? 'Sin plan asignado',
                    style: const TextStyle(color: AppColors.neutral700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusPill(
                        label: status.label,
                        color: status.color,
                      ),
                      if (created != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Alta: $created',
                          style: const TextStyle(color: AppColors.neutral700),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral700),
          ],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.fallback, this.logoUrl});

  final String fallback;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8EDF5),
      backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
      child: logoUrl == null
          ? Text(
              fallback,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            )
          : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusMeta {
  _StatusMeta(this.label, this.color);

  final String label;
  final Color color;
}

_StatusMeta _statusMeta(EstadoSuscripcion? status) {
  switch (status) {
    case EstadoSuscripcion.activo:
      return _StatusMeta('Activo', AppColors.successGreen);
    case EstadoSuscripcion.prueba:
      return _StatusMeta('Prueba', AppColors.infoBlue);
    case EstadoSuscripcion.vencido:
      return _StatusMeta('Vencido', AppColors.warningOrange);
    case EstadoSuscripcion.cancelado:
      return _StatusMeta('Cancelado', AppColors.neutral700);
    default:
      return _StatusMeta('Sin estado', AppColors.neutral400);
  }
}
