import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/role_section_card.dart';

class EmployeeHomeView extends StatelessWidget {
  const EmployeeHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empleado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          RoleSectionCard(
            title: 'Marcación y asistencia',
            items: [
              'Registrar entrada/salida con GPS o QR según sucursal.',
              'Revisar si la marcación quedó dentro de la geocerca.',
              'Subir evidencia fotográfica cuando la política lo requiera.',
            ],
          ),
          RoleSectionCard(
            title: 'Historial y comprobantes',
            items: [
              'Consultar marcas previas con fecha, hora y ubicación.',
              'Ver horas extras identificadas y turnos nocturnos.',
            ],
          ),
          RoleSectionCard(
            title: 'Permisos y datos personales',
            items: [
              'Crear solicitudes de permiso con documentos adjuntos.',
              'Revisar estado de aprobación y comentarios.',
              'Actualizar teléfono y foto de perfil.',
            ],
          ),
        ],
      ),
    );
  }
}
