import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/role_section_card.dart';

class AuditorHomeView extends StatelessWidget {
  const AuditorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auditor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          RoleSectionCard(
            title: 'Revisión de cumplimiento',
            items: [
              'Auditar jornadas, descansos y horas extras contra LOE.',
              'Validar integridad de registros de asistencia con evidencias.',
              'Marcar hallazgos y solicitar justificaciones a RRHH.',
            ],
          ),
          RoleSectionCard(
            title: 'Reportes y exportes',
            items: [
              'Exportar datos crudos (CSV/Excel) por organización.',
              'Descargar logs de auditoría con trazabilidad completa.',
            ],
          ),
          RoleSectionCard(
            title: 'Acceso de solo lectura',
            items: [
              'Visualizar tablas y métricas sin modificar datos.',
              'Consultar alertas legales y su estado de atención.',
            ],
          ),
        ],
      ),
    );
  }
}
