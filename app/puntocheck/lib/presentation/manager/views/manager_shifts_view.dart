import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class ManagerShiftsView extends StatelessWidget {
  const ManagerShiftsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Turnos y horarios',
            child: EmptyState(
              title: 'No hay turnos asignados',
              message: 'Crea o asigna turnos para tu área o sucursal.',
              icon: Icons.schedule_outlined,
            ),
          ),
          SectionCard(
            title: 'Geocercas y QR',
            child: EmptyState(
              title: 'Configura geocercas',
              message:
                  'Verifica radios de geocerca y QR rotativos para sucursales sin GPS.',
              icon: Icons.map_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
