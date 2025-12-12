import 'package:flutter/material.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Card moderno para mostrar una plantilla de horario
class ScheduleTemplateCard extends StatelessWidget {
  final PlantillasHorarios template;
  final int? assignedEmployees;
  final VoidCallback? onTap;

  const ScheduleTemplateCard({
    super.key,
    required this.template,
    this.assignedEmployees,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dias = template.diasLaborales ?? [1, 2, 3, 4, 5];
    final diasNames = dias.map(_getDayName).toList();

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
              // Header: Nombre + badge nocturno
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                  if (template.esRotativo == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.nights_stay_rounded,
                            size: 14,
                            color: Color(0xFF1A237E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Rotativo',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Horarios
              Row(
                children: [
                  _TimeChip(
                    icon: Icons.login_rounded,
                    time: _formatTime(template.horaEntrada),
                    label: 'Entrada',
                  ),
                  const SizedBox(width: 12),
                  _TimeChip(
                    icon: Icons.logout_rounded,
                    time: _formatTime(template.horaSalida),
                    label: 'Salida',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // DÃ­as laboraleswrap
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: diasNames.map((day) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Footer: Descanso + empleados
              Row(
                children: [
                  Icon(
                    Icons.coffee_outlined,
                    size: 16,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Descanso: ${template.tiempoDescansoMinutos ?? 60} min',
                    style: const TextStyle(
                      color: AppColors.neutral700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (assignedEmployees != null) ...[
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$assignedEmployees',
                      style: const TextStyle(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    // time viene como "HH:mm:ss", retornar "HH:mm"
    if (time == null || time.isEmpty) return "--";
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  String _getDayName(int day) {
    const names = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return day >= 1 && day <= 7 ? names[day] : '';
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  final String label;

  const _TimeChip({
    required this.icon,
    required this.time,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.neutral700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.neutral900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

