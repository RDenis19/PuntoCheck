import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista para crear una nueva plantilla de horarios
class OrgAdminNewScheduleView extends ConsumerStatefulWidget {
  const OrgAdminNewScheduleView({super.key});

  @override
  ConsumerState<OrgAdminNewScheduleView> createState() =>
      _OrgAdminNewScheduleViewState();
}

class _OrgAdminNewScheduleViewState
    extends ConsumerState<OrgAdminNewScheduleView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descansoController = TextEditingController(text: '60');

  TimeOfDay _horaEntrada = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaSalida = const TimeOfDay(hour: 17, minute: 0);
  Set<int> _diasSeleccionados = {1, 2, 3, 4, 5}; // Lun-Vie por defecto
  bool _esRotativo = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descansoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Plantilla de Horario'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la plantilla',
                    hintText: 'Ej: Turno Mañana',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Hora de Entrada
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hora de Entrada',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: InkWell(
                    onTap: () => _selectTime(context, isEntry: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _horaEntrada.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // Hora de Salida
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hora de Salida',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: InkWell(
                    onTap: () => _selectTime(context, isEntry: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _horaSalida.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Descanso
                TextFormField(
                  controller: _descansoController,
                  decoration: InputDecoration(
                    labelText: 'Tiempo de descanso (minutos)',
                    prefixIcon: const Icon(Icons.coffee_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el tiempo de descanso';
                    }
                    final min = int.tryParse(value);
                    if (min == null || min < 0) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Días laborales
                const Text(
                  'Días Laborales',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DayChip(
                      day: 1,
                      label: 'Lun',
                      isSelected: _diasSeleccionados.contains(1),
                      onTap: () => _toggleDay(1),
                    ),
                    _DayChip(
                      day: 2,
                      label: 'Mar',
                      isSelected: _diasSeleccionados.contains(2),
                      onTap: () => _toggleDay(2),
                    ),
                    _DayChip(
                      day: 3,
                      label: 'Mie',
                      isSelected: _diasSeleccionados.contains(3),
                      onTap: () => _toggleDay(3),
                    ),
                    _DayChip(
                      day: 4,
                      label: 'Jue',
                      isSelected: _diasSeleccionados.contains(4),
                      onTap: () => _toggleDay(4),
                    ),
                    _DayChip(
                      day: 5,
                      label: 'Vie',
                      isSelected: _diasSeleccionados.contains(5),
                      onTap: () => _toggleDay(5),
                    ),
                    _DayChip(
                      day: 6,
                      label: 'Sáb',
                      isSelected: _diasSeleccionados.contains(6),
                      onTap: () => _toggleDay(6),
                    ),
                    _DayChip(
                      day: 7,
                      label: 'Dom',
                      isSelected: _diasSeleccionados.contains(7),
                      onTap: () => _toggleDay(7),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Toggle nocturno
                SwitchListTile(
                  value: _esRotativo,
                  onChanged: (value) {
                    setState(() => _esRotativo = value);
                  },
                  title: const Text('Turno Rotativo'),
                  subtitle: const Text('Incluye rotación de turnos'),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 32),

                // Botón guardar
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Crear Plantilla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_diasSeleccionados.contains(day)) {
        _diasSeleccionados.remove(day);
      } else {
        _diasSeleccionados.add(day);
      }
    });
  }

  Future<void> _selectTime(BuildContext context,
      {required bool isEntry}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isEntry ? _horaEntrada : _horaSalida,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isEntry) {
          _horaEntrada = time;
        } else {
          _horaSalida = time;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día laboral')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await ref.read(profileProvider.future);
      final orgId = profile?.organizacionId;
      if (orgId == null) throw Exception('No org ID');

      await ScheduleService.instance.createScheduleTemplate(
        organizacionId: orgId,
        nombre: _nombreController.text.trim(),
        horaEntrada: '${_horaEntrada.hour.toString().padLeft(2, '0')}:${_horaEntrada.minute.toString().padLeft(2, '0')}:00',
        horaSalida: '${_horaSalida.hour.toString().padLeft(2, '0')}:${_horaSalida.minute.toString().padLeft(2, '0')}:00',
        tiempoDescansoMinutos: int.parse(_descansoController.text),
        diasLaborales: _diasSeleccionados.toList()..sort(),
        esRotativo: _esRotativo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla creada exitosamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear plantilla: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DayChip extends StatelessWidget {
  final int day;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.neutral300,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primaryRed : AppColors.neutral700,
          ),
        ),
      ),
    );
  }
}
