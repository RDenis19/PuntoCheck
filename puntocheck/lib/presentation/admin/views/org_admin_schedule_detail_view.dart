import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';
import 'package:puntocheck/presentation/admin/views/org_admin_edit_schedule_view.dart';
import 'package:puntocheck/services/schedule_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Vista de detalle de plantilla de horario
class OrgAdminScheduleDetailView extends ConsumerStatefulWidget {
  final PlantillasHorarios schedule;

  const OrgAdminScheduleDetailView({super.key, required this.schedule});

  @override
  ConsumerState<OrgAdminScheduleDetailView> createState() =>
      _OrgAdminScheduleDetailViewState();
}

class _OrgAdminScheduleDetailViewState
    extends ConsumerState<OrgAdminScheduleDetailView> {
  late PlantillasHorarios _schedule;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final dias = _schedule.diasLaborales ?? [1, 2, 3, 4, 5];

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_schedule.nombre),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.neutral900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed,
                        AppColors.primaryRed.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _schedule.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.login_rounded,
                              label: 'Entrada',
                              value: _formatTime(_schedule.horaEntrada),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.logout_rounded,
                              label: 'Salida',
                              value: _formatTime(_schedule.horaSalida),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Detalles
                _DetailCard(
                  icon: Icons.access_time_outlined,
                  title: 'Horario',
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Hora de Entrada',
                        value: _formatTime(_schedule.horaEntrada),
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Hora de Salida',
                        value: _formatTime(_schedule.horaSalida),
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'Tolerancia de entrada',
                        value:
                            '${_schedule.toleranciaEntradaMinutos ?? 10} min',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _DetailCard(
                  icon: Icons.view_timeline_outlined,
                  title: 'Turnos',
                  child: Builder(
                    builder: (context) {
                      final turnos = [
                        ..._schedule.turnos,
                      ]..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));

                      if (turnos.isEmpty) {
                        return const Text('Sin turnos registrados');
                      }

                      return Column(
                        children: [
                          for (var i = 0; i < turnos.length; i++) ...[
                            _DetailRow(
                              label: turnos[i].orden != null
                                  ? '${turnos[i].nombreTurno} (#${turnos[i].orden})'
                                  : turnos[i].nombreTurno,
                              value:
                                  '${_formatTime(turnos[i].horaInicio)} - ${_formatTime(turnos[i].horaFin)}'
                                  '${turnos[i].esDiaSiguiente == true ? ' (+1 dia)' : ''}',
                            ),
                            if (i != turnos.length - 1) const Divider(),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _DetailCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Dias laborales',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dias.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getDayName(day),
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                if (_schedule.esRotativo == true)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.rotate_right, color: Color(0xFF1A237E)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Turno rotativo - Incluye rotacion de turnos',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return "--";
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  String _getDayName(int day) {
    const names = [
      '',
      'Lunes',
      'Martes',
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
      'Domingo',
    ];
    return day >= 1 && day <= 7 ? names[day] : '';
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrgAdminEditScheduleView(schedule: _schedule),
      ),
    );

    if (changed == true) {
      try {
        final refreshed = await ScheduleService.instance
            .getScheduleTemplateById(_schedule.id);
        if (!mounted) return;
        setState(() {
          _schedule = refreshed;
          _changed = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plantilla actualizada')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error recargando: $e')));
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: const Text(
          'Estas seguro de eliminar esta plantilla de horario? '
          'Los empleados asignados perderan su horario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ScheduleService.instance.deleteScheduleTemplate(_schedule.id);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plantilla eliminada')));
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.neutral700),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.neutral700, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}
