import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/widgets/outlined_dark_button.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, embedded ? 100 : 20),
      children: [
        _ProfileHeader(
          onEditAvatar: () => _showSnackBar(context, 'Actualizar foto (mock).'),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Cuenta'),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Información personal',
          subtitle: 'Edita tu nombre, teléfono, correo o contraseña',
          onTap: () {
            // TODO(backend): validar permisos antes de permitir cambios sobre la información personal.
            Navigator.pushNamed(context, AppRouter.employeePersonalInfo);
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Preferencia'),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Modo Oscuro',
          subtitle: 'Cambia la apariencia del sistema',
          onTap: () {
            // TODO(backend): persistir la preferencia de tema para mantenerla sincronizada entre dispositivos.
            _showSnackBar(context, 'Modo oscuro (mock).');
          },
        ),
        _SettingsTile(
          icon: Icons.language,
          title: 'Lenguaje',
          subtitle: 'Selecciona tu idioma preferido',
          onTap: () {
            // TODO(backend): guardar el lenguaje preferido del usuario para cargarlo al iniciar sesión.
            _showSnackBar(context, 'Cambio de lenguaje (mock).');
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Soporte'),
        _SettingsTile(
          icon: Icons.fingerprint,
          title: 'Huella Dactilar',
          subtitle: 'Configura biometría para ingresar',
          onTap: () {
            // TODO(backend): integrar biometría nativa y sincronizar la preferencia desde backend/Auth.
            _showSnackBar(context, 'Huella dactilar (mock).');
          },
        ),
        const SizedBox(height: 24),
        OutlinedDarkButton(
          text: 'Cerrar sesión',
          onPressed: () {
            // TODO(backend): cerrar la sesión real limpiando tokens y actualizando backend.
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.login,
              (_) => false,
            );
          },
        ),
      ],
    );

    if (embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Ajustes',
          style: TextStyle(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEditAvatar});

  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryRed,
                child: Icon(Icons.person, color: AppColors.white, size: 40),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onEditAvatar,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pablo Criollo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'pavincrik@gmail.com',
                  style: TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 4),
                // TODO(backend): foto, nombre y correo deben venir del perfil autenticado.
                Text(
                  'Empleado · ID 00231',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.backgroundDark,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.primaryRed),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
