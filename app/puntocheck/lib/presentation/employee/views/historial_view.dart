import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/work_shift_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/history_item_card.dart';

class HistorialView extends ConsumerStatefulWidget {
  const HistorialView({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends ConsumerState<HistorialView> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    Widget content = historyAsync.when(
      data: (history) {
        final filtered = _applyFilter(history);

        if (filtered.isEmpty) {
          return _emptyState();
        }

        final monthLabel = _monthLabel(filtered.first.date);
        final summary = _buildSummary(filtered);

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 100 : 16),
          children: [
            _buildMonthHeader(monthLabel),
            const SizedBox(height: 18),
            _buildSummaryRow(summary),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 12),
            for (final shift in filtered)
              HistoryItemCard(
                dayNumber: shift.date.day.toString().padLeft(2, '0'),
                dayLabel: _dayLabel(shift.date),
                registrosLabel: '1 registro',
                entrada: _formatTime(shift.checkInTime),
                salida: shift.checkOutTime != null ? _formatTime(shift.checkOutTime!) : '--',
                total: _formatDuration(shift.durationMinutes),
                estado: _statusLabel(shift.status),
                ubicacion: shift.checkInAddress ?? 'Sin direccion',
                estadoColor: _statusColor(shift.status),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error al cargar historial')),
    );

    if (widget.embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Historial',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: content,
    );
  }

  List<WorkShift> _applyFilter(List<WorkShift> history) {
    if (_selectedFilter == 1) {
      return history.where((h) => h.status == AttendanceStatus.puntual).toList();
    }
    if (_selectedFilter == 2) {
      return history.where((h) => h.status == AttendanceStatus.tardanza).toList();
    }
    return history;
  }

  Map<String, int> _buildSummary(List<WorkShift> history) {
    final punctual = history.where((h) => h.status == AttendanceStatus.puntual).length;
    final late = history.where((h) => h.status == AttendanceStatus.tardanza).length;
    return {
      'dias': history.length,
      'puntuales': punctual,
      'tardanzas': late,
    };
  }

  Widget _buildMonthHeader(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left)),
        Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
          ],
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _buildSummaryRow(Map<String, int> summary) {
    Widget infoCard(String title, String value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        infoCard('Dias', '${summary['dias']}', AppColors.primaryRed, Icons.calendar_today),
        infoCard(
          'Puntuales',
          '${summary['puntuales']}',
          AppColors.successGreen,
          Icons.verified_outlined,
        ),
        infoCard(
          'Tardanzas',
          '${summary['tardanzas']}',
          AppColors.warningOrange,
          Icons.error_outline,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Puntuales', 'Tardanzas'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(filters.length, (index) {
        final bool isSelected = _selectedFilter == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryRed
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 56,
              color: AppColors.backgroundDark.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Aun no hay asistencias',
              style: TextStyle(
                color: AppColors.backgroundDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _dayLabel(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.tardanza:
        return 'Tarde';
      case AttendanceStatus.falta:
        return 'Falta';
      case AttendanceStatus.salida_temprana:
        return 'Salida temprana';
      case AttendanceStatus.puntual:
      default:
        return 'Puntual';
    }
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.tardanza:
        return AppColors.warningOrange;
      case AttendanceStatus.falta:
        return AppColors.primaryRed;
      case AttendanceStatus.salida_temprana:
        return AppColors.infoBlue;
      case AttendanceStatus.puntual:
      default:
        return AppColors.successGreen;
    }
  }
}
