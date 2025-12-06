import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class AdminTeamView extends StatelessWidget {
  const AdminTeamView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Equipo y roles',
            child: EmptyState(
              title: 'Sin empleados cargados',
              message: 'Cuando agregues empleados y managers, aparecerán aquí.',
              icon: Icons.groups_outlined,
            ),
          ),
          SectionCard(
            title: 'Asignaciones y turnos',
            child: EmptyState(
              title: 'No hay asignaciones',
              message: 'Asigna plantillas de horario por área o sucursal.',
              icon: Icons.calendar_today_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
