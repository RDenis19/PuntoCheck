import 'package:flutter/material.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Chip de filtro por estado de permiso
class LeaveFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const LeaveFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.neutral900  // Negro cuando seleccionado
              : Colors.white,          // Blanco cuando no seleccionado
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? AppColors.neutral900 
                : AppColors.neutral300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neutral900.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected 
                ? Colors.white          // Texto blanco cuando seleccionado
                : AppColors.neutral700, // Texto gris cuando no seleccionado
          ),
        ),
      ),
    );
  }
}

/// Sección de filtros para permisos
class LeaveFiltersSection extends StatelessWidget {
  final EstadoAprobacion? selectedFilter;
  final Function(EstadoAprobacion?) onFilterChanged;

  const LeaveFiltersSection({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Filtrar por estado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              LeaveFilterChip(
                label: 'Todos',
                isSelected: selectedFilter == null,
                onTap: () => onFilterChanged(null),
                color: AppColors.neutral700,
              ),
              const SizedBox(width: 8),
              LeaveFilterChip(
                label: 'Pendientes',
                isSelected: selectedFilter == EstadoAprobacion.pendiente,
                onTap: () => onFilterChanged(EstadoAprobacion.pendiente),
                color: AppColors.warningOrange,
              ),
              const SizedBox(width: 8),
              LeaveFilterChip(
                label: 'Aprobados',
                isSelected: selectedFilter == EstadoAprobacion.aprobadoManager,
                onTap: () => onFilterChanged(EstadoAprobacion.aprobadoManager),
                color: AppColors.successGreen,
              ),
              const SizedBox(width: 8),
              LeaveFilterChip(
                label: 'Rechazados',
                isSelected: selectedFilter == EstadoAprobacion.rechazado,
                onTap: () => onFilterChanged(EstadoAprobacion.rechazado),
                color: AppColors.errorRed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
