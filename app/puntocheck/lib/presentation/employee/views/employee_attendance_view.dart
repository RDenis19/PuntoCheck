import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class EmployeeAttendanceView extends StatelessWidget {
  const EmployeeAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Historial de asistencia',
            child: EmptyState(
              title: 'Sin registros',
              message:
                  'Tus marcas de entrada/salida aparecerán aquí con ubicación y evidencias.',
              icon: Icons.history_toggle_off,
            ),
          ),
          SectionCard(
            title: 'Check-in / Check-out',
            child: EmptyState(
              title: 'Listo para marcar',
              message: 'Cuando el servicio esté conectado podrás marcar asistencia.',
              icon: Icons.fingerprint,
            ),
          ),
        ],
      ),
    );
  }
}
