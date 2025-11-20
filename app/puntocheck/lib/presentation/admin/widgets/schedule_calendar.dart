import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

typedef DaySelectedCallback = void Function(DateTime date);

class ScheduleCalendar extends StatelessWidget {
  const ScheduleCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDays,
    required this.onDayToggle,
  });

  final DateTime focusedMonth;
  final Set<DateTime> selectedDays;
  final DaySelectedCallback onDayToggle;

  @override
  Widget build(BuildContext context) {
    final List<DateTime?> days = _buildMonthDays(focusedMonth);
    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: days.length,
          itemBuilder: (_, index) {
            final day = days[index];
            if (day == null) {
              return const SizedBox.shrink();
            }
            final bool isSelected = selectedDays.any((d) => _isSameDay(d, day));
            return GestureDetector(
              onTap: () => onDayToggle(day),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.backgroundDark
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.backgroundDark
                        : AppColors.black.withValues(alpha: 0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.backgroundDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // TODO(backend): persistir esta selección de días en reglas de horario.
      ],
    );
  }

  List<DateTime?> _buildMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final List<DateTime?> result = [];

    final int leadingEmpty = (firstDay.weekday + 6) % 7;
    for (int i = 0; i < leadingEmpty; i++) {
      result.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      result.add(DateTime(month.year, month.month, day));
    }
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
