import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/models/employee_schedule.dart';
import 'package:puntocheck/services/schedule_display_helper.dart';
import 'package:puntocheck/models/turnos_jornada.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class EmployeeScheduleView extends ConsumerWidget {
  const EmployeeScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(employeeScheduleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Mi horario'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(employeeScheduleProvider);
          final schedule = await ref.refresh(employeeScheduleProvider.future);
          if (schedule == null) {
            ref.invalidate(employeeNextScheduleProvider);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            scheduleAsync.when(
              data: (schedule) => _ScheduleBody(schedule: schedule),
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(
                message: 'No se pudo cargar tu horario.\n$e',
                onRetry: () => ref.invalidate(employeeScheduleProvider),
              ),
            ),
            if (scheduleAsync.maybeWhen(data: (s) => s == null, orElse: () => false)) ...[
              const SizedBox(height: 14),
              _NextScheduleSection(nextAsync: ref.watch(employeeNextScheduleProvider)),
            ],
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Importante',
              icon: Icons.info_outline,
              child: const Text(
                'Aquí solo puedes ver tu horario. Los horarios y turnos los asigna tu Manager/Org Admin.',
                style: TextStyle(color: AppColors.neutral700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  const _ScheduleBody({required this.schedule});

  final EmployeeSchedule? schedule;

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    if (schedule == null) {
      return Column(
        children: const [
          _InfoCard(
            title: 'Tu turno hoy',
            icon: Icons.event_busy,
            child: Text(
              'No tienes un horario asignado para hoy.',
              style: TextStyle(color: AppColors.neutral700),
            ),
          ),
        ],
      );
    }

    final plantilla = schedule!.plantilla;
    final asignacion = schedule!.asignacion;
    final turns = ScheduleDisplayHelper.sortedTurns(plantilla);
    final segments = turns.isNotEmpty
        ? ScheduleDisplayHelper.formatTurnsSegments(turns)
        : ScheduleDisplayHelper.formatTemplateSummary(plantilla);

    final tolerance = plantilla.toleranciaEntradaMinutos;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final vigenciaFin = asignacion.fechaFin != null ? dateFmt.format(asignacion.fechaFin!) : 'Sin fin';
    final isRotative = plantilla.esRotativo == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: 'Tu turno hoy',
          icon: Icons.schedule,
          trailing: isRotative
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'Rotativo',
                    style: TextStyle(
                      color: AppColors.warningOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segments,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plantilla.nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.verified_outlined,
                    label: 'Vigencia',
                    value: '${dateFmt.format(asignacion.fechaInicio)} → $vigenciaFin',
                  ),
                  _MetaPill(
                    icon: Icons.tag_outlined,
                    label: 'Plantilla',
                    value: _shortId(plantilla.id),
                  ),
                  _MetaPill(
                    icon: Icons.timer_outlined,
                    label: 'Tolerancia',
                    value: tolerance == null ? '—' : '$tolerance min',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Días laborables',
          icon: Icons.calendar_month_outlined,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ScheduleDisplayHelper.buildWeekdayChips(
                diasLaborales: plantilla.diasLaborales,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Turnos',
          icon: Icons.view_timeline_outlined,
          child: turns.isEmpty
              ? const Text(
                  'Este horario no tiene turnos configurados.',
                  style: TextStyle(color: AppColors.neutral700),
                )
              : Column(
                  children: [
                    for (final t in turns) ...[
                      _TurnCard(turno: t),
                      if (t != turns.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _NextScheduleSection extends StatelessWidget {
  const _NextScheduleSection({required this.nextAsync});

  final AsyncValue<EmployeeSchedule?> nextAsync;

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    return nextAsync.when(
      data: (next) {
        if (next == null) {
          return const _InfoCard(
            title: 'Próximo horario',
            icon: Icons.next_plan_outlined,
            child: Text(
              'No tienes horarios programados próximamente.',
              style: TextStyle(color: AppColors.neutral700),
            ),
          );
        }

        final plantilla = next.plantilla;
        final asignacion = next.asignacion;
        final turns = ScheduleDisplayHelper.sortedTurns(plantilla);
        final segments = turns.isNotEmpty
            ? ScheduleDisplayHelper.formatTurnsSegments(turns)
            : ScheduleDisplayHelper.formatTemplateSummary(plantilla);
        final dateFmt = DateFormat('dd/MM/yyyy');
        final fin = asignacion.fechaFin != null ? dateFmt.format(asignacion.fechaFin!) : 'Sin fin';

        return _InfoCard(
          title: 'Próximo horario',
          icon: Icons.next_plan_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segments,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plantilla.nombre,
                style: const TextStyle(color: AppColors.neutral600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.verified_outlined,
                    label: 'Vigencia',
                    value: '${dateFmt.format(asignacion.fechaInicio)} → $fin',
                  ),
                  _MetaPill(
                    icon: Icons.tag_outlined,
                    label: 'Plantilla',
                    value: _shortId(plantilla.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const _InfoCard(
        title: 'Próximo horario',
        icon: Icons.next_plan_outlined,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
      ),
      error: (e, _) => _InfoCard(
        title: 'Próximo horario',
        icon: Icons.next_plan_outlined,
        child: Text(
          'No se pudo cargar el próximo horario.\n$e',
          style: const TextStyle(color: AppColors.errorRed),
        ),
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({required this.turno});

  final TurnosJornada turno;

  @override
  Widget build(BuildContext context) {
    final start = ScheduleDisplayHelper.formatHm(turno.horaInicio);
    final end = ScheduleDisplayHelper.formatHm(turno.horaFin);
    final crosses = turno.esDiaSiguiente == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time, color: AppColors.infoBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turno.nombreTurno,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  crosses ? '$start–$end (+1)' : '$start–$end',
                  style: const TextStyle(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
          if (crosses)
            const Icon(Icons.nights_stay_outlined, color: AppColors.neutral500),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.neutral600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Icon(icon, color: AppColors.primaryRed),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      title: 'Tu turno hoy',
      icon: Icons.schedule,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Tu turno hoy',
      icon: Icons.error_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppColors.errorRed)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}
