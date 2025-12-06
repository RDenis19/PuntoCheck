import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/section_card.dart';

class EmployeeProfileView extends StatelessWidget {
  const EmployeeProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Datos personales',
            child: EmptyState(
              title: 'Sin datos cargados',
              message: 'Cuando el perfil esté conectado podrás editar teléfono y foto.',
              icon: Icons.person_outline,
            ),
          ),
          SectionCard(
            title: 'Seguridad',
            child: EmptyState(
              title: 'Gestión de contraseña',
              message: 'Aquí podrás actualizar tu contraseña y 2FA cuando esté disponible.',
              icon: Icons.lock_outline,
            ),
          ),
          SectionCard(
            title: 'Documentos',
            child: EmptyState(
              title: 'Sin documentos',
              message: 'Tus permisos y evidencias se listarán aquí.',
              icon: Icons.folder_shared_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
