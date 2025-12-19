import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class AuditorComplianceView extends StatelessWidget {
  const AuditorComplianceView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Violaciones LOE',
            child: EmptyState(
              title: 'Sin violaciones registradas',
              message: 'Se listarán jornadas excesivas, descansos insuficientes y faltas.',
              icon: Icons.scale_outlined,
            ),
          ),
          SectionCard(
            title: 'Justificaciones',
            child: EmptyState(
              title: 'Sin justificaciones pendientes',
              message: 'Las respuestas de RRHH a hallazgos aparecerán aquí.',
              icon: Icons.rule_folder_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
