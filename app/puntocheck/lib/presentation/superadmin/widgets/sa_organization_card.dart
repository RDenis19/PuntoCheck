import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SaOrganizationCard extends ConsumerWidget {
  const SaOrganizationCard({
    super.key,
    required this.organization,
    required this.onTap,
    this.totalEmployees,
    this.activeToday,
    this.attendanceAverage,
    this.isLoading = false,
    this.hasStatsError = false,
  });

  final Organization organization;
  final VoidCallback onTap;
  final int? totalEmployees;
  final int? activeToday;
  final int? attendanceAverage;
  final bool isLoading;
  final bool hasStatsError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color statusColor = switch (organization.status) {
      OrgStatus.activa => AppColors.successGreen,
      OrgStatus.prueba => AppColors.warningOrange,
      OrgStatus.suspendida => AppColors.primaryRed,
    };

    final brandColor = _brandColor();
    final employeesText = totalEmployees != null ? '$totalEmployees' : '--';
    final activeTodayText = activeToday != null ? '$activeToday' : '--';
    final attendanceText = attendanceAverage != null
        ? '$attendanceAverage%'
        : '--';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(ref, brandColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.backgroundDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contacto: ${organization.contactEmail ?? 'N/A'}',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.black.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Alta: ${_formatDate(organization.createdAt)}',
                              style: TextStyle(
                                color: AppColors.black.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    color: statusColor,
                    text: organization.status.name,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoColumn(
                    label: 'Empleados',
                    value: employeesText,
                    isLoading: isLoading,
                  ),
                  _InfoColumn(
                    label: 'Activos hoy',
                    value: activeTodayText,
                    isLoading: isLoading,
                  ),
                  _InfoColumn(
                    label: 'Promedio',
                    value: attendanceText,
                    isLoading: isLoading,
                  ),
                ],
              ),
              if (hasStatsError) ...[
                const SizedBox(height: 10),
                const _StatsWarning(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(WidgetRef ref, Color brandColor) {
    if (organization.logoUrl == null || organization.logoUrl!.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              brandColor.withValues(alpha: 0.2),
              brandColor.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: Center(
          child: Text(
            organization.name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.hardEdge,
      child: FutureBuilder<String>(
        future: ref
            .read(storageServiceProvider)
            .resolveOrgLogoUrl(organization.logoUrl!, expiresInSeconds: 3600),
        builder: (context, snapshot) {
          final url = snapshot.data ?? organization.logoUrl!;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              backgroundColor: brandColor.withValues(alpha: 0.15),
              child: Text(
                organization.name.substring(0, 1),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _brandColor() {
    final hex = organization.brandColor.replaceAll('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_monthShort(date.month)} ${date.year}';

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
  const _InfoColumn({
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.black.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          if (isLoading)
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w800,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatsWarning extends StatelessWidget {
  const _StatsWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.primaryRed, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No pudimos cargar las estadisticas. Intenta mas tarde.',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
