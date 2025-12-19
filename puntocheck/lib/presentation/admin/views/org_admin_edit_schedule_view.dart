import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminEditScheduleView extends ConsumerStatefulWidget {
  final PlantillasHorarios schedule;

  const OrgAdminEditScheduleView({super.key, required this.schedule});

  @override
  ConsumerState<OrgAdminEditScheduleView> createState() =>
      _OrgAdminEditScheduleViewState();
}

class _OrgAdminEditScheduleViewState
    extends ConsumerState<OrgAdminEditScheduleView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _toleranceController;
  late Set<int> _diasSeleccionados;
  late bool _esRotativo;
  late List<_TurnoEditForm> _turnos;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule.nombre);
    _toleranceController = TextEditingController(
      text: '${widget.schedule.toleranciaEntradaMinutos ?? 10}',
    );
    _diasSeleccionados = {
      ...(widget.schedule.diasLaborales ?? const [1, 2, 3, 4, 5]),
    };
    _esRotativo = widget.schedule.esRotativo ?? false;

    final sorted = [...widget.schedule.turnos]
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));
    _turnos = sorted
        .map(
          (t) => _TurnoEditForm(
            id: t.id,
            orden: t.orden ?? 1,
            nombre: t.nombreTurno,
            inicio: _parseTimeOfDay(t.horaInicio),
            fin: _parseTimeOfDay(t.horaFin),
            esDiaSiguiente: t.esDiaSiguiente ?? false,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar plantilla'),
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
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la plantilla',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toleranceController,
                  decoration: InputDecoration(
                    labelText: 'Tolerancia de entrada (minutos)',
                    prefixIcon: const Icon(Icons.timer_outlined),
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
                      return 'Valor invalido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Turnos del horario',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._turnos.map(_buildTurnoCard),
                const SizedBox(height: 20),
                const Text(
                  'Dias laborales',
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
                      label: 'Sab',
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
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _esRotativo,
                  onChanged: (value) => setState(() => _esRotativo = value),
                  title: const Text('Turno rotativo'),
                  subtitle: const Text('Incluye rotacion de turnos'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
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
                          'Guardar cambios',
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

  Widget _buildTurnoCard(_TurnoEditForm turno) {
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
            TextFormField(
              initialValue: turno.nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre del turno',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (v) => turno.nombre = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Inicio',
                    time: turno.inicio,
                    onPick: (t) => setState(() => turno.inicio = t),
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
              onChanged: (v) =>
                  setState(() => turno.esDiaSiguiente = v ?? false),
              title: const Text('Termina al dia siguiente'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
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

  TimeOfDay _parseTimeOfDay(String hhmmss) {
    final parts = hhmmss.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un dia laboral')),
      );
      return;
    }

    final tolerance = int.tryParse(_toleranceController.text) ?? 10;

    final turnosPayload = _turnos.map((t) {
      if (t.inicio == null || t.fin == null) {
        throw Exception('Completa las horas de todos los turnos');
      }
      return {
        'id': t.id,
        'plantilla_id': widget.schedule.id,
        'nombre_turno': (t.nombre ?? '').trim().isEmpty
            ? 'Turno ${t.orden}'
            : t.nombre,
        'hora_inicio': _formatTime(t.inicio!),
        'hora_fin': _formatTime(t.fin!),
        'orden': t.orden,
        'es_dia_siguiente': t.esDiaSiguiente,
      };
    }).toList();

    final turnosError = _validateTurnos(turnosPayload);
    if (turnosError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(turnosError)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ScheduleService.instance.updateScheduleTemplate(
        plantillaId: widget.schedule.id,
        nombre: _nameController.text.trim(),
        toleranciaEntradaMinutos: tolerance,
        diasLaborales: _diasSeleccionados.toList()..sort(),
        esRotativo: _esRotativo,
      );

      await ScheduleService.instance.updateScheduleTurns(
        plantillaId: widget.schedule.id,
        turnos: turnosPayload,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TurnoEditForm {
  final String id;
  final int orden;
  String? nombre;
  TimeOfDay? inicio;
  TimeOfDay? fin;
  bool esDiaSiguiente;

  _TurnoEditForm({
    required this.id,
    required this.orden,
    this.nombre,
    this.inicio,
    this.fin,
    this.esDiaSiguiente = false,
  });
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
              const Icon(Icons.access_time, size: 20),
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
