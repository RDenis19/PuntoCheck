import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class ManagerApprovalsView extends StatelessWidget {
  const ManagerApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Permisos pendientes',
            child: EmptyState(
              title: 'No hay solicitudes',
              message: 'Aquí verás solicitudes de 1-2 días para aprobar o rechazar.',
              icon: Icons.mark_email_unread_outlined,
            ),
          ),
          SectionCard(
            title: 'Días compensatorios',
            child: EmptyState(
              title: 'Sin solicitudes',
              message: 'Cuando sugieras un día compensatorio, aparecerá aquí.',
              icon: Icons.beach_access_outlined,
            ),
          ),
          SectionCard(
            title: 'Justificaciones',
            child: EmptyState(
              title: 'Sin justificaciones pendientes',
              message:
                  'Las justificaciones de inasistencias o salidas anticipadas se verán aquí.',
              icon: Icons.rule_folder_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
