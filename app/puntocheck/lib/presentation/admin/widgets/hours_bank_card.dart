import 'package:flutter/material.dart';
import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card para mostrar un registro de banco de horas
class HoursBankCard extends StatelessWidget {
  final BancoHorasCompensatorias record;
  final String? employeeName;
  final VoidCallback? onTap;

  const HoursBankCard({
    super.key,
    required this.record,
    this.employeeName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = record.cantidadHoras > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.neutral200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Empleado + Horas
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPositive
                            ? [
                                AppColors.successGreen.withValues(alpha: 0.8),
                                AppColors.successGreen,
                              ]
                            : [
                                AppColors.errorRed.withValues(alpha: 0.8),
                                AppColors.errorRed,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isPositive ? Icons.add : Icons.remove,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName ?? 'Empleado',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record.concepto,
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Horas
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? AppColors.successGreen.withValues(alpha: 0.12)
                          : AppColors.errorRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${record.cantidadHoras.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color:
                            isPositive ? AppColors.successGreen : AppColors.errorRed,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              if (record.aceptaRenunciaPago == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: AppColors.successGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Acepta renuncia de pago',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
