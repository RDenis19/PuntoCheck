import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/models/enums.dart';

class SaOrganizationCard extends StatelessWidget {
  const SaOrganizationCard({
    super.key,
    required this.organization,
    required this.onTap,
  });

  final Organization organization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (organization.status) {
      OrgStatus.activa => AppColors.successGreen,
      OrgStatus.prueba => AppColors.warningOrange,
      OrgStatus.suspendida => AppColors.primaryRed,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contacto: ${organization.contactEmail ?? 'N/A'}',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(color: statusColor, text: organization.status.name),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoColumn(
                    label: 'Empleados',
                    value: '--', // TODO: Fetch count
                  ),
                  _InfoColumn(
                    label: 'Activos hoy',
                    value: '--', // TODO: Fetch active
                  ),
                  _InfoColumn(
                    label: 'Promedio',
                    value: '--', // TODO: Fetch avg
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Desde ${_formatDate(organization.createdAt)}',
                style: TextStyle(
                  color: AppColors.black.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (organization.logoUrl == null || organization.logoUrl!.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.15),
        child: Text(
          organization.name.substring(0, 1),
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundImage: NetworkImage(organization.logoUrl!),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthShort(date.month)} ${date.year}';

  String _formatDateTime(DateTime date) {
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(date)}, $time';
  }

  String _monthShort(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.black.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}


