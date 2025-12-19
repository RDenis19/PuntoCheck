import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class AuditorReportsView extends StatelessWidget {
  const AuditorReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Exportes de datos',
            child: EmptyState(
              title: 'Sin exportes generados',
              message: 'CSV/Excel y reportes legales aparecerán aquí.',
              icon: Icons.file_present_outlined,
            ),
          ),
          SectionCard(
            title: 'Evidencias y permisos',
            child: EmptyState(
              title: 'Nada para descargar',
              message: 'Adjuntos de permisos y evidencias se listarán para revisión.',
              icon: Icons.folder_shared_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
