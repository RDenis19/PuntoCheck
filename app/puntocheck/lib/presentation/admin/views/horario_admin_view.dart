import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/admin/widgets/schedule_calendar.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

class HorarioAdminView extends StatefulWidget {
  const HorarioAdminView({super.key});

  @override
  State<HorarioAdminView> createState() => _HorarioAdminViewState();
}

class _HorarioAdminViewState extends State<HorarioAdminView> {
  DateTime _focusedMonth = DateTime(2025, 10);
  final Set<DateTime> _selectedDays = {};
  final _entradaController = TextEditingController(text: '08:00');
  final _salidaController = TextEditingController(text: '17:00');
  final _horasController = TextEditingController(text: '8');

  @override
  void dispose() {
    _entradaController.dispose();
    _salidaController.dispose();
    _horasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ScheduleCalendar(
            focusedMonth: _focusedMonth,
            selectedDays: _selectedDays,
            onDayToggle: (day) {
              setState(() {
                final existing = _selectedDays.firstWhere(
                  (d) => _isSameDay(d, day),
                  orElse: () => DateTime(0),
                );
                if (existing.year != 0) {
                  _selectedDays.remove(existing);
                } else {
                  _selectedDays.add(day);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legend(color: AppColors.primaryRed, label: 'Corta'),
              const SizedBox(width: 12),
              _legend(color: AppColors.warningOrange, label: 'Reducida'),
              const SizedBox(width: 12),
              _legend(color: AppColors.successGreen, label: 'Completa'),
            ],
          ),
          const SizedBox(height: 24),
          TextFieldIcon(
            controller: _entradaController,
            hintText: 'Hora de entrada',
            prefixIcon: Icons.login,
          ),
          const SizedBox(height: 16),
          TextFieldIcon(
            controller: _salidaController,
            hintText: 'Hora de salida',
            prefixIcon: Icons.logout,
          ),
          const SizedBox(height: 16),
          TextFieldIcon(
            controller: _horasController,
            hintText: 'Horas de trabajo',
            prefixIcon: Icons.access_time,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Guardar Horario',
            onPressed: () {
              // TODO(backend): enviar reglas de horario para estas fechas seleccionadas.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Horario guardado para ${_selectedDays.length} días (mock).',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
        ),
      ],
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}



