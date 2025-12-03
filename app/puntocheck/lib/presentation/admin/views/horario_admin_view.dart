import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/work_schedule_model.dart';
import 'package:puntocheck/presentation/admin/widgets/schedule_calendar.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class HorarioAdminView extends ConsumerStatefulWidget {
  const HorarioAdminView({super.key});

  @override
  ConsumerState<HorarioAdminView> createState() => _HorarioAdminViewState();
}

class _HorarioAdminViewState extends ConsumerState<HorarioAdminView> {
  DateTime _focusedMonth = DateTime.now();
  final Set<DateTime> _selectedDates = {};

  final Map<int, _DaySchedule> _week = {
    for (var i = 1; i <= 7; i++) i: _DaySchedule.defaults(),
  };

  // Controles para aplicar en bloque a los dias seleccionados del calendario.
  TimeOfDay _bulkStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _bulkEnd = const TimeOfDay(hour: 17, minute: 0);
  ShiftCategory _bulkType = ShiftCategory.completa;

  Future<void> _save() async {
    final profile = await ref.read(profileProvider.future);
    if (profile?.organizationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay organizacion asociada.')),
      );
      return;
    }

    final enabledDays =
        _week.entries.where((entry) => entry.value.enabled).toList();
    if (enabledDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa al menos un dia.')),
      );
      return;
    }

    final invalidRanges = enabledDays
        .where((entry) => !_isStartBeforeEnd(entry.value.start, entry.value.end))
        .toList();
    if (invalidRanges.isNotEmpty) {
      final firstInvalid = invalidRanges.first.key;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Revisa la hora de ${_dayName(firstInvalid)}: la salida debe ser despues de la entrada.',
          ),
        ),
      );
      return;
    }

    final controller = ref.read(scheduleControllerProvider.notifier);
    var savedCount = 0;
    for (final entry in enabledDays) {
      final cfg = entry.value;
      final schedule = WorkSchedule(
        id: '',
        organizationId: profile!.organizationId!,
        userId: null, // Horario general
        dayOfWeek: entry.key % 7, // Domingo pasa a 0 para mantener 0-6.
        startTime: _formatBackendTime(cfg.start),
        endTime: _formatBackendTime(cfg.end),
        type: cfg.type,
      );
      await controller.createSchedule(schedule);
      final status = ref.read(scheduleControllerProvider);
      if (status.hasError) break;
      savedCount++;
    }

    final state = ref.read(scheduleControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No pudimos guardar el horario. Revisa tu rol o permisos. Detalle: ${state.error}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horario guardado para $savedCount dias.'),
        ),
      );
    }
  }

  void _applyBulkToSelected() {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona dias en el calendario.')),
      );
      return;
    }
    setState(() {
      for (final date in _selectedDates) {
        final weekday = date.weekday; // 1-7
        final cfg = _week[weekday];
        if (cfg != null) {
          cfg.enabled = true;
          cfg.start = _bulkStart;
          cfg.end = _bulkEnd;
          cfg.type = _bulkType;
        }
      }
      _selectedDates.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horario aplicado a dias seleccionados.')),
    );
  }

  Future<void> _pickBulk(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _bulkStart : _bulkEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _bulkStart = picked;
        } else {
          _bulkEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(scheduleControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerTip(),
          const SizedBox(height: 12),
          _CalendarSection(
            focusedMonth: _focusedMonth,
            selectedDates: _selectedDates,
            bulkStart: _bulkStart,
            bulkEnd: _bulkEnd,
            bulkType: _bulkType,
            onPrevMonth: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            }),
            onNextMonth: () => setState(() {
              _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            }),
            onDayToggle: (day) {
              setState(() {
                final existing = _selectedDates.firstWhere(
                  (d) => _isSameDay(d, day),
                  orElse: () => DateTime(0),
                );
                if (existing.year != 0) {
                  _selectedDates.remove(existing);
                } else {
                  _selectedDates.add(day);
                }
              });
            },
            onPickStart: () => _pickBulk(true),
            onPickEnd: () => _pickBulk(false),
            onTypeChanged: (type) => setState(() => _bulkType = type),
            onApply: _applyBulkToSelected,
          ),
          const SizedBox(height: 12),
          ..._week.entries.map((entry) => _DayCard(
                label: _dayName(entry.key),
                config: entry.value,
                onToggle: (v) => setState(() => entry.value.enabled = v),
                onPickStart: () => _pickTime(entry.value, true),
                onPickEnd: () => _pickTime(entry.value, false),
                onTypeChanged: (t) => setState(() => entry.value.type = t),
              )),
          const SizedBox(height: 20),
          PrimaryButton(
            text: isLoading ? 'Guardando...' : 'Guardar horario',
            enabled: !isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(_DaySchedule config, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? config.start : config.end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          config.start = picked;
        } else {
          config.end = picked;
        }
      });
    }
  }

  Widget _headerTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Crea el horario base',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.backgroundDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Usa el calendario para seleccionar dias y aplicar el mismo horario en bloque. '
            'Para horarios individuales ve a la ficha del empleado.',
            style: TextStyle(
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.backgroundDark,
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int day) {
    const names = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miercoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sabado',
      7: 'Domingo',
    };
    return names[day] ?? 'Dia';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isStartBeforeEnd(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }

  String _formatBackendTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.focusedMonth,
    required this.selectedDates,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayToggle,
    required this.bulkStart,
    required this.bulkEnd,
    required this.bulkType,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onTypeChanged,
    required this.onApply,
  });

  final DateTime focusedMonth;
  final Set<DateTime> selectedDates;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime) onDayToggle;
  final TimeOfDay bulkStart;
  final TimeOfDay bulkEnd;
  final ShiftCategory bulkType;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<ShiftCategory> onTypeChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(focusedMonth.month)} ${focusedMonth.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Calendario y edicion rapida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selecciona dias y aplica un mismo horario',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: _InfoBadge(
                  icon: Icons.event_available,
                  label: '${selectedDates.length} seleccionados',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _MonthButton(
                  icon: Icons.chevron_left,
                  onTap: onPrevMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ),
                ),
                _MonthButton(
                  icon: Icons.chevron_right,
                  onTap: onNextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ScheduleCalendar(
            focusedMonth: focusedMonth,
            selectedDays: selectedDates,
            onDayToggle: onDayToggle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  label: 'Entrada',
                  value: bulkStart.format(context),
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeChip(
                  label: 'Salida',
                  value: bulkEnd.format(context),
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ShiftCategory.values
                .map(
                  (type) => _ShiftChip(
                    type: type,
                    selected: bulkType == type,
                    onTap: () => onTypeChanged(type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Aplicar a dias seleccionados',
            onPressed: onApply,
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.backgroundDark),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.backgroundDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.label,
    required this.config,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onTypeChanged,
  });

  final String label;
  final _DaySchedule config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<ShiftCategory> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = config.enabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled
              ? AppColors.black.withValues(alpha: 0.06)
              : AppColors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.primaryRed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.backgroundDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEnabled ? 'Activo' : 'Pausado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isEnabled
                                ? AppColors.primaryRed
                                : AppColors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isEnabled,
                    onChanged: onToggle,
                  activeColor: AppColors.primaryRed,
                ),
              ],
            ),
          const SizedBox(height: 12),
          IgnorePointer(
            ignoring: !isEnabled,
            child: Opacity(
              opacity: isEnabled ? 1 : 0.45,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimeChip(
                          label: 'Entrada',
                          value: config.start.format(context),
                          onTap: onPickStart,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimeChip(
                          label: 'Salida',
                          value: config.end.format(context),
                          onTap: onPickEnd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tipo de jornada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ShiftCategory.values.map((type) {
                      final selected = config.type == type;
                      return _ShiftChip(
                        type: type,
                        selected: selected,
                        onTap: () => onTypeChanged(type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ShiftCategory type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig(type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? cfg.color.withValues(alpha: 0.15)
              : AppColors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cfg.color
                : AppColors.black.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cfg.icon,
              color: selected ? cfg.color : AppColors.backgroundDark,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              cfg.label,
              style: TextStyle(
                color: selected
                    ? cfg.color
                    : AppColors.backgroundDark.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySchedule {
  _DaySchedule({
    required this.enabled,
    required this.start,
    required this.end,
    required this.type,
  });

  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
  ShiftCategory type;

  factory _DaySchedule.defaults() => _DaySchedule(
        enabled: true,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
        type: ShiftCategory.completa,
      );
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                label.toLowerCase().contains('entrada')
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                size: 18,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCfg {
  const _TypeCfg(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_TypeCfg _typeConfig(ShiftCategory type) {
  switch (type) {
    case ShiftCategory.reducida:
      return _TypeCfg('Turno reducido', AppColors.infoBlue, Icons.timelapse);
    case ShiftCategory.corta:
      return _TypeCfg('Turno corto', AppColors.warningOrange, Icons.timer);
    case ShiftCategory.descanso:
      return _TypeCfg('Descanso', AppColors.successGreen, Icons.self_improvement);
    case ShiftCategory.completa:
    default:
      return _TypeCfg('Turno completo', AppColors.primaryRed, Icons.work_history);
  }
}
