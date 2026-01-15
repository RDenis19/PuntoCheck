import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/models/perfiles.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/providers/core_providers.dart';
import 'package:puntocheck/providers/manager_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import '../widgets/manager_assign_schedule_sheet.dart';

/// Vista de detalle de empleado para Manager (solo lectura).
///
/// Muestra información completa del empleado:
/// - Datos personales
/// - Historial de asistencia
///
/// **Sin opciones de edición** (el Manager solo visualiza)
class ManagerPersonDetailView extends ConsumerStatefulWidget {
  final String userId;

  const ManagerPersonDetailView({super.key, required this.userId});

  @override
  ConsumerState<ManagerPersonDetailView> createState() =>
      _ManagerPersonDetailViewState();
}

class _ManagerPersonDetailViewState
    extends ConsumerState<ManagerPersonDetailView> {
  Future<void> _editEmployeeBasics(Perfiles perfil) async {
    final telefonoCtrl = TextEditingController(text: perfil.telefono ?? '');
    final cargoCtrl = TextEditingController(text: perfil.cargo ?? '');
    var saving = false;

    Future<void> submit(StateSetter setModalState) async {
      final telefono = telefonoCtrl.text.trim();
      final cargo = cargoCtrl.text.trim();

      setModalState(() => saving = true);
      try {
        await ref.read(staffServiceProvider).updateProfile(perfil.id, {
          'telefono': telefono.isEmpty ? null : telefono,
          'cargo': cargo.isEmpty ? null : cargo,
        });

        ref
          ..invalidate(managerPersonProvider(perfil.id))
          ..invalidate(managerTeamProvider);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos actualizados'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo actualizar: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      } finally {
        setModalState(() => saving = false);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Editar cargo y teléfono'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cargoCtrl,
                    decoration: const InputDecoration(labelText: 'Cargo'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : () => submit(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(managerPersonProvider(widget.userId));
    final attendanceAsync = ref.watch(
      managerPersonAttendanceProvider(widget.userId),
    );

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Detalle del empleado'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryRed),
        actions: [
          perfilAsync.when(
            data: (perfil) => IconButton(
              tooltip: 'Editar cargo/teléfono',
              onPressed: () => _editEmployeeBasics(perfil),
              icon: const Icon(Icons.edit_rounded),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(managerPersonProvider(widget.userId));
          ref.invalidate(managerPersonAttendanceProvider(widget.userId));
          await Future.wait([
            ref.read(managerPersonProvider(widget.userId).future),
            ref.read(managerPersonAttendanceProvider(widget.userId).future),
          ]);
        },
        child: perfilAsync.when(
          data: (perfil) => _DetailContent(
            perfil: perfil,
            attendanceAsync: attendanceAsync,
            scheduleAsync: ref.watch(
              managerEmployeeActiveScheduleProvider(widget.userId),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: 'Error cargando empleado: $e'),
        ),
      ),
    );
  }
}

// ============================================================================
// Contenido principal del detalle
// ============================================================================

class _DetailContent extends StatelessWidget {
  final Perfiles perfil;
  final AsyncValue<List<RegistrosAsistencia>> attendanceAsync;
  final AsyncValue<Map<String, dynamic>?> scheduleAsync;

  const _DetailContent({
    required this.perfil,
    required this.attendanceAsync,
    required this.scheduleAsync,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderSection(perfil: perfil),
        const SizedBox(height: 16),

        // 1. Información Personal (Acordeón)
        _SectionAccordion(
          title: 'Información Personal',
          icon: Icons.person_rounded,
          initiallyExpanded: false,
          children: [_PersonalInfoContent(perfil: perfil)],
        ),
        const SizedBox(height: 12),

        // 2. Horario Asignado (Acordeón)
        _SectionAccordion(
          title: 'Horario Asignado',
          icon: Icons.calendar_today_rounded,
          initiallyExpanded: true, // Relevante para el manager
          children: [
            _ScheduleContent(
              scheduleAsync: scheduleAsync,
              employeeId: perfil.id,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Historial de Asistencia (Acordeón)
        _SectionAccordion(
          title: 'Historial de Asistencia',
          icon: Icons.history_rounded,
          initiallyExpanded: false,
          children: [_AttendanceContent(attendanceAsync: attendanceAsync)],
        ),
      ],
    );
  }
}

// ============================================================================
// Header (Mantenemos igual por ahora, visualmente impactante)
// ============================================================================

class _HeaderSection extends StatelessWidget {
  final Perfiles perfil;

  const _HeaderSection({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final initials =
        '${perfil.nombres.isNotEmpty ? perfil.nombres[0] : ''}'
                '${perfil.apellidos.isNotEmpty ? perfil.apellidos[0] : ''}'
            .toUpperCase();
    final active = perfil.activo != false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child:
                  perfil.fotoPerfilUrl != null &&
                      perfil.fotoPerfilUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        perfil.fotoPerfilUrl!,
                        fit: BoxFit.cover,
                        width: 84,
                        height: 84,
                      ),
                    )
                  : Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Nombre completo
          Text(
            perfil.nombreCompleto,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              perfil.rol?.value.toUpperCase() ?? 'SIN ROL',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Estado activo/inactivo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.greenAccent : Colors.white60,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                active ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ============================================================================
// Widget Genérico de Acordeón
// ============================================================================

class _SectionAccordion extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _SectionAccordion({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.neutral900,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}

// ============================================================================
// Contenido: Información Personal
// ============================================================================

class _PersonalInfoContent extends StatelessWidget {
  final Perfiles perfil;

  const _PersonalInfoContent({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        _InfoItem(
          icon: Icons.email_rounded,
          iconColor: AppColors.neutral600,
          label: 'Correo electrónico',
          value: (perfil.email ?? perfil.correo) ?? 'No registrado',
        ),
        const SizedBox(height: 16),
        _InfoItem(
          icon: Icons.phone_rounded,
          iconColor: AppColors.neutral600,
          label: 'Teléfono',
          value: perfil.telefono ?? 'No registrado',
        ),
        const SizedBox(height: 16),
        _InfoItem(
          icon: Icons.badge_rounded,
          iconColor: AppColors.neutral600,
          label: 'Cédula',
          value: perfil.cedula ?? 'No registrado',
        ),
        const SizedBox(height: 16),
        _InfoItem(
          icon: Icons.work_rounded,
          iconColor: AppColors.neutral600,
          label: 'Cargo',
          value: perfil.cargo?.isNotEmpty == true
              ? perfil.cargo!
              : 'No asignado',
        ),
        if (perfil.creadoEn != null) ...[
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.neutral600,
            label: 'Fecha de ingreso',
            value: DateFormat('dd/MM/yyyy').format(perfil.creadoEn!),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// Contenido: Horario
// ============================================================================

class _ScheduleContent extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>?> scheduleAsync;
  final String employeeId;

  const _ScheduleContent({
    required this.scheduleAsync,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        scheduleAsync.when(
          data: (schedule) {
            if (schedule == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_busy_rounded, color: AppColors.neutral500),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sin horario activo asignado',
                        style: TextStyle(color: AppColors.neutral600),
                      ),
                    ),
                  ],
                ),
              );
            }

            final template = Map<String, dynamic>.from(
              schedule['plantillas_horarios'] as Map,
            );
            final turnos =
                (template['turnos_jornada'] as List?)?.cast<dynamic>() ??
                const [];
            final dias =
                (template['dias_laborales'] as List?)?.cast<dynamic>() ??
                const [];
            final tolerancia = template['tolerancia_entrada_minutos'] ?? 10;
            return Column(
              children: [
                const Divider(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['nombre'] ?? 'Horario Personalizado',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.neutral900,
                          ),
                        ),
                        Text(
                          _formatTurnos(turnos),
                          style: const TextStyle(
                            color: AppColors.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoItem(
                  icon: Icons.calendar_view_week_rounded,
                  iconColor: AppColors.neutral600,
                  label: 'Días Laborales',
                  value: _formatDias(dias),
                ),
                const SizedBox(height: 8),
                _InfoItem(
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.neutral600,
                  label: 'Tolerancia de entrada',
                  value: '$tolerancia min',
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Error al cargar horario: $e',
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ManagerAssignScheduleSheet(
                  preselectedEmployeeId: employeeId,
                  onAssigned: () {
                    ref.invalidate(
                      managerEmployeeActiveScheduleProvider(employeeId),
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: const Text('Cambiar Horario'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: const BorderSide(color: AppColors.primaryRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDias(List<dynamic> dias) {
    if (dias.isEmpty) return 'No especificado';
    const names = ['', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final mapped = dias
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .map((d) => names[d])
        .where((s) => s.isNotEmpty)
        .toList();
    return mapped.isEmpty ? 'No especificado' : mapped.join(', ');
  }

  static String _formatTurnos(List<dynamic> turnos) {
    if (turnos.isEmpty) return '--';
    final sorted = [...turnos]
      ..sort((a, b) {
        final ma = (a as Map?) ?? const {};
        final mb = (b as Map?) ?? const {};
        final oa = int.tryParse(ma['orden']?.toString() ?? '') ?? 0;
        final ob = int.tryParse(mb['orden']?.toString() ?? '') ?? 0;
        return oa.compareTo(ob);
      });

    return sorted
        .map((t) {
          final m = (t as Map?) ?? const {};
          final start = _formatTime(m['hora_inicio']?.toString());
          final end = _formatTime(m['hora_fin']?.toString());
          final nextDay = (m['es_dia_siguiente'] == true) ? ' (+1)' : '';
          return '$start-$end$nextDay';
        })
        .join(', ');
  }

  static String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

// ============================================================================
// Contenido: Asistencia
// ============================================================================

class _AttendanceContent extends StatelessWidget {
  final AsyncValue<List<RegistrosAsistencia>> attendanceAsync;

  const _AttendanceContent({required this.attendanceAsync});

  @override
  Widget build(BuildContext context) {
    return attendanceAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: _EmptyAttendance(),
          );
        }
        return Column(
          children: [
            const Divider(),
            const SizedBox(height: 8),
            ...logs.map((log) => _AttendanceCard(log: log)),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => const _ErrorView(message: 'Error cargando asistencia'),
    );
  }
}

// ============================================================================
// Item de información individual
// ============================================================================

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Card de asistencia individual
// ============================================================================

class _AttendanceCard extends StatelessWidget {
  final RegistrosAsistencia log;

  const _AttendanceCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy - hh:mm a');
    final tipo = log.tipoRegistro ?? '';
    final icon = _iconForType(tipo);
    final color = _colorForType(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForType(tipo),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(log.fechaHoraMarcacion.toLocal()),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          if (log.estaDentroGeocerca != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: log.estaDentroGeocerca!
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                log.estaDentroGeocerca!
                    ? Icons.location_on
                    : Icons.location_off,
                color: log.estaDentroGeocerca! ? Colors.green : Colors.orange,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'entrada':
        return Icons.login_rounded;
      case 'salida':
        return Icons.logout_rounded;
      case 'inicio_break':
        return Icons.coffee_rounded;
      case 'fin_break':
        return Icons.free_breakfast_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'entrada':
        return Colors.green;
      case 'salida':
        return Colors.blue;
      case 'inicio_break':
        return Colors.orange;
      case 'fin_break':
        return Colors.purple;
      default:
        return AppColors.neutral600;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'inicio_break':
        return 'Inicio de Descanso';
      case 'fin_break':
        return 'Fin de Descanso';
      default:
        return 'Registro';
    }
  }
}

// ============================================================================
// Estado vacío de asistencia
// ============================================================================

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral200,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin registros de asistencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este empleado aún no ha registrado\nninguna marcación',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Vista de error
// ============================================================================

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
