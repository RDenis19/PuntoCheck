import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/presentation/employee/widgets/employee_header.dart';
import 'package:puntocheck/presentation/employee/views/employee_mark_attendance_view.dart';
import 'package:puntocheck/presentation/employee/views/employee_notifications_view.dart';
import 'package:puntocheck/providers/employee_providers.dart';
import 'package:puntocheck/services/employee_service.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/plantillas_horarios.dart';

class EmployeeHomeView extends ConsumerStatefulWidget {
  const EmployeeHomeView({super.key});

  @override
  ConsumerState<EmployeeHomeView> createState() => _EmployeeHomeViewState();
}

class _EmployeeHomeViewState extends ConsumerState<EmployeeHomeView> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(employeeScheduleProvider);
    final EmployeeSchedule? schedule = scheduleAsync.valueOrNull;
    final RegistrosAsistencia? lastAttendance =
        ref.watch(lastAttendanceProvider).valueOrNull;

    // Fecha actual formateada
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d ' 'de' ' MMMM', 'es').format(now);
    final formattedDate = dateString[0].toUpperCase() + dateString.substring(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Gris suave muy profesional (Google/Facebook style)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmployeeNotificationsView()),
          );
        },
        child: const Icon(Icons.notifications, color: AppColors.primaryRed),
      ),
      body: Column(
        children: [
          // Header Reutilizable
          const EmployeeHeader(),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FECHA DE HOY
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TARJETA PRINCIPAL DE ACCIÓN (Marking)
                  _buildMainActionCard(context, ref, lastAttendance),

                  const SizedBox(height: 24),

                  // SECCIÓN: TU TURNO
                  const Text(
                    'Tu Turno de Hoy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildShiftCard(schedule),

                  const SizedBox(height: 24),

                  // SECCIÓN: RESUMEN RÁPIDO
                  const Text(
                    'Resumen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.access_time_filled,
                          color: AppColors.infoBlue,
                          value: '0h 0m',
                          label: 'Trabajadas',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.check_circle,
                          color: AppColors.successGreen,
                          value: 'A tiempo',
                          label: 'Estado',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta Grande de Acción Principal
  Widget _buildMainActionCard(
    BuildContext context,
    WidgetRef ref,
    RegistrosAsistencia? lastRecord,
  ) {
    final bool isEntry =
        lastRecord == null || lastRecord.tipoRegistro == 'salida';
    final String actionLabel = isEntry ? 'Marcar Entrada' : 'Marcar Salida';
    final IconData actionIcon = isEntry ? Icons.login : Icons.logout;
    final Color actionColor = isEntry ? AppColors.successGreen : AppColors.primaryRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
           // Icono circular grande animado (simulado)
           GestureDetector(
             onTap: () {
               // Navegar a la vista de marcación
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (_) => EmployeeMarkAttendanceView(
                     actionType: isEntry ? 'entrada' : 'salida',
                   ),
                 ),
               );
             },
             child: Container(
               width: 100,
               height: 100,
               decoration: BoxDecoration(
                 color: actionColor.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
                 border: Border.all(color: actionColor.withValues(alpha: 0.2), width: 8),
               ),
               child: Icon(
                 Icons.fingerprint,
                 size: 48,
                 color: actionColor,
               ),
             ),
           ),
           const SizedBox(height: 20),
           Text(
             actionLabel,
             style: TextStyle(
               fontSize: 20,
               fontWeight: FontWeight.bold,
               color: AppColors.neutral900,
             ),
           ),
           const SizedBox(height: 4),
           Text(
             isEntry ? 'Comienza tu jornada' : 'Finaliza tu jornada',
             style: const TextStyle(
               fontSize: 14,
               color: AppColors.neutral500,
             ),
           ),
        ],
      ),
    );
  }

  /// Tarjeta de Turno
  Widget _buildShiftCard(EmployeeSchedule? schedule) {
    if (schedule == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_busy, color: AppColors.neutral500),
            SizedBox(width: 12),
            Text('No tienes turno asignado para hoy', style: TextStyle(color: AppColors.neutral600)),
          ],
        ),
      );
    }

    final plantilla = schedule.plantilla;
    final horarioStr = _formatTemplateRange(plantilla);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: AppColors.infoBlue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                horarioStr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plantilla.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTemplateRange(PlantillasHorarios plantilla) {
    final turnos = [...plantilla.turnos]
      ..sort((a, b) => (a.orden ?? 0).compareTo(b.orden ?? 0));
    if (turnos.isEmpty) {
      final entrada = (plantilla.horaEntrada ?? '--');
      final salida = (plantilla.horaSalida ?? '--');
      final start = entrada.length >= 5 ? entrada.substring(0, 5) : entrada;
      final end = salida.length >= 5 ? salida.substring(0, 5) : salida;
      return '$start - $end';
    }

    final first = turnos.first;
    final last = turnos.last;
    final start = (first.horaInicio ?? '--');
    final end = (last.horaFin ?? '--');

    final startStr = start.length >= 5 ? start.substring(0, 5) : start;
    final endStr = end.length >= 5 ? end.substring(0, 5) : end;
    final suffix = (last.esDiaSiguiente == true) ? ' (+1)' : '';
    return '$startStr - $endStr$suffix';
  }

  Widget _buildSummaryItem({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
