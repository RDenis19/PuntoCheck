import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Parámetros legales y operativos',
            child: EmptyState(
              title: 'Configura tolerancias y descansos',
              message:
                  'Define tolerancia de entrada, descansos mínimos y radios de geocerca.',
              icon: Icons.rule_folder_outlined,
            ),
          ),
          SectionCard(
            title: 'Geocercas y QR',
            child: EmptyState(
              title: 'Sin geocercas configuradas',
              message:
                  'Agrega sucursales con radio permitido y habilita QR rotativo si lo requieres.',
              icon: Icons.map_outlined,
            ),
          ),
          SectionCard(
            title: 'White-label',
            child: EmptyState(
              title: 'Personaliza tu marca',
              message:
                  'Define color primario, logo y nombre de la app para tu organización.',
              icon: Icons.palette_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
