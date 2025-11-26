import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeStatsCards extends StatelessWidget {
  const EmployeeStatsCards({super.key, required this.stats});

  final List<EmployeeStatData> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      style: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class EmployeeStatData {
  const EmployeeStatData({required this.label, required this.value});

  final String label;
  final String value;
}
