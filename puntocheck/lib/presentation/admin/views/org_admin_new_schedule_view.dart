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
  final _toleranciaController = TextEditingController(text: '10');

  final List<_TurnoForm> _turnos = [_TurnoForm(nombre: 'Turno 1')];
  final Set<int> _diasSeleccionados = {1, 2, 3, 4, 5}; // Lun-Vie por defecto
  bool _esRotativo = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _toleranciaController.dispose();
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
                    hintText: 'Ej: Turno Manana',
                    prefixIcon: const Icon(Icons.badge_rounded),
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

                // Turnos
                const Text(
                  'Turnos del horario',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._turnos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final turno = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.neutral200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: turno.nombre,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del turno',
                                    prefixIcon: Icon(Icons.badge_rounded),
                                  ),
                                  onChanged: (v) => turno.nombre = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_turnos.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: AppColors.errorRed,
                                  ),
                                  onPressed: () {
                                    setState(() => _turnos.removeAt(idx));
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _TimePickerTile(
                                  label: 'Inicio',
                                  time: turno.inicio,
                                  onPick: (t) =>
                                      setState(() => turno.inicio = t),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TimePickerTile(
                                  label: 'Fin',
                                  time: turno.fin,
                                  onPick: (t) => setState(() => turno.fin = t),
                                ),
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            value: turno.esDiaSiguiente,
                            onChanged: (v) {
                              setState(() => turno.esDiaSiguiente = v ?? false);
                            },
                            title: const Text('Termina al d\u00eda siguiente'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _turnos.add(
                        _TurnoForm(nombre: 'Turno ${_turnos.length + 1}'),
                      );
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar turno'),
                ),

                const SizedBox(height: 20),

                // Tolerancia
                TextFormField(
                  controller: _toleranciaController,
                  decoration: InputDecoration(
                    labelText: 'Tolerancia de entrada (minutos)',
                    prefixIcon: const Icon(Icons.timer_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa la tolerancia de entrada';
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                  subtitle: const Text('Incluye rotacion de turnos'),
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

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
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

      final turnosPayload = _turnos.map((t) {
        if (t.inicio == null || t.fin == null) {
          throw Exception('Completa las horas de todos los turnos');
        }
        final inicio = _formatTime(t.inicio!);
        final fin = _formatTime(t.fin!);
        return {
          'nombre_turno': t.nombre?.isNotEmpty == true ? t.nombre : null,
          'hora_inicio': inicio,
          'hora_fin': fin,
          'es_dia_siguiente': t.esDiaSiguiente,
        };
      }).toList();

      final turnosError = _validateTurnos(turnosPayload);
      if (turnosError != null) throw Exception(turnosError);

      await ScheduleService.instance.createScheduleTemplate(
        organizacionId: orgId,
        nombre: _nombreController.text.trim(),
        turnos: turnosPayload,
        toleranciaEntradaMinutos: int.parse(_toleranciaController.text),
        diasLaborales: _diasSeleccionados.toList()..sort(),
        esRotativo: _esRotativo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla creada exitosamente')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear plantilla: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPick;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
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
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                time != null ? time!.format(context) : '--:--',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnoForm {
  String? nombre;
  TimeOfDay? inicio;
  TimeOfDay? fin;
  bool esDiaSiguiente = false;

  _TurnoForm({this.nombre});
}

String? _validateTurnos(List<Map<String, dynamic>> turnos) {
  int toMinutes(String hhmmss) {
    final parts = hhmmss.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  final intervals = <({int idx, int start, int end})>[];

  for (var i = 0; i < turnos.length; i++) {
    final t = turnos[i];
    final startLocal = toMinutes(t['hora_inicio'] as String);
    final endLocal = toMinutes(t['hora_fin'] as String);
    final esDiaSiguiente = t['es_dia_siguiente'] == true;

    if (esDiaSiguiente && endLocal > startLocal) {
      return 'Turno ${i + 1}: si marcas "dia siguiente", la hora fin debe ser menor o igual a la hora inicio.';
    }

    if (!esDiaSiguiente && endLocal <= startLocal) {
      return 'Turno ${i + 1}: la hora fin debe ser mayor que la hora inicio (o marca "dia siguiente").';
    }

    final start = startLocal;
    final end = esDiaSiguiente ? (endLocal + 24 * 60) : endLocal;
    intervals.add((idx: i, start: start, end: end));
  }

  intervals.sort((a, b) => a.start.compareTo(b.start));

  for (var i = 1; i < intervals.length; i++) {
    final prev = intervals[i - 1];
    final cur = intervals[i];
    if (cur.start < prev.end) {
      return 'Los turnos se solapan: Turno ${prev.idx + 1} y Turno ${cur.idx + 1}.';
    }
  }

  return null;
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
