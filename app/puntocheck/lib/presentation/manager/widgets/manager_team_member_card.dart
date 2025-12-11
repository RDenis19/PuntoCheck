import 'package:flutter/material.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/presentation/manager/views/manager_person_detail_view.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card reutilizable para mostrar un miembro del equipo del manager.
/// 
/// Muestra:
/// - Avatar con inicial
/// - Nombre completo
/// - Cargo
/// - Teléfono
/// - Estado (activo/inactivo)
class ManagerTeamMemberCard extends StatelessWidget {
  final Perfiles employee;
  final String? scheduleName;
  final VoidCallback? onTap;

  const ManagerTeamMemberCard({
    super.key,
    required this.employee,
    this.scheduleName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = employee.activo ?? true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
            () {
              // Navegar a la vista de detalle del empleado
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerPersonDetailView(userId: employee.id),
                ),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.neutral200 : AppColors.neutral300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryRed.withValues(alpha: 0.1)
                      : AppColors.neutral200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    employee.nombres.isNotEmpty
                        ? employee.nombres[0].toUpperCase()
                        : 'E',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? AppColors.primaryRed
                          : AppColors.neutral600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.nombreCompleto,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge de estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.successGreen.withValues(alpha: 0.1)
                                : AppColors.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: isActive
                                    ? AppColors.successGreen
                                    : AppColors.neutral500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? AppColors.successGreen
                                      : AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (scheduleName != null) ...[
                           const SizedBox(width: 8),
                           Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.infoBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                scheduleName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.infoBlue,
                                ),
                              ),
                           ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Cargo
                    if (employee.cargo != null && employee.cargo!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline,
                            size: 14,
                            color: AppColors.neutral600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              employee.cargo!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Teléfono
                    if (employee.telefono != null &&
                        employee.telefono!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.neutral600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            employee.telefono!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Icono de flecha
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.neutral400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
