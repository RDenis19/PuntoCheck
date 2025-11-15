import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/features/shared/widgets/primary_button.dart';

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  String nombre = 'Pablo';
  String apellido = 'Criollo';
  String correo = 'pavincrik@gmail.com';
  String telefono = '+593 999 999 999';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Información Personal',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppColors.primaryRed.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO(backend): abrir flujo para cambiar foto (cámara/galería)
                        // y subirla al backend, actualizando el avatar del empleado.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cambiar foto (mock).')),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Datos Personales', Icons.person_outline),
            const SizedBox(height: 12),
            _InfoEditableField(
              label: 'Nombre',
              value: nombre,
              onEdit: () => _openEditModal(
                title: 'Editar Nombre',
                initialValue: nombre,
                onSave: (value) => setState(() => nombre = value),
              ),
            ),
            _InfoEditableField(
              label: 'Apellido',
              value: apellido,
              onEdit: () => _openEditModal(
                title: 'Editar Apellido',
                initialValue: apellido,
                onSave: (value) => setState(() => apellido = value),
              ),
            ),
            // TODO(backend): al guardar cambios se debe llamar al endpoint del perfil
            // para mantener sincronizados los datos en todos los dispositivos.
            const SizedBox(height: 24),
            _buildSectionTitle('Información de Contacto', Icons.mail_outline),
            const SizedBox(height: 12),
            _InfoEditableField(
              label: 'Correo Electrónico',
              value: correo,
              onEdit: () => _openEditModal(
                title: 'Editar Correo',
                initialValue: correo,
                onSave: (value) => setState(() => correo = value),
              ),
            ),
            _InfoEditableField(
              label: 'Teléfono',
              value: telefono,
              onEdit: () => _openEditModal(
                title: 'Editar Teléfono',
                initialValue: telefono,
                onSave: (value) => setState(() => telefono = value),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Seguridad', Icons.lock_outline),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.black.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                onTap: _openPasswordModal,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: AppColors.primaryRed,
                  ),
                ),
                title: const Text(
                  'Cambiar Contraseña',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                subtitle: Text(
                  'Actualiza tu contraseña regularmente.',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Guardar Cambios',
              onPressed: () {
                // TODO(backend): enviar todos los campos modificados en un solo request
                // para persistir la información actualizada en el backend.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cambios guardados (mock).')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundDark,
          ),
        ),
      ],
    );
  }

  Future<void> _openEditModal({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Guardar',
                onPressed: () {
                  onSave(controller.text.trim());
                  Navigator.of(context).pop();
                  // TODO(backend): al confirmar se debe persistir el cambio para que
                  // quede almacenado en la cuenta del usuario.
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPasswordModal() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar Contraseña',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Nueva contraseña',
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirmar contraseña',
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Actualizar contraseña',
                onPressed: () {
                  // TODO(backend): validar contraseñas y llamar al endpoint Auth
                  // para cambiar la clave del usuario autenticado.
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada (mock).'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoEditableField extends StatelessWidget {
  const _InfoEditableField({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryRed),
          ),
        ],
      ),
    );
  }
}

