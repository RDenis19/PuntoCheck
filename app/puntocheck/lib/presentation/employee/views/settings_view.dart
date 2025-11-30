import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({
    super.key,
    this.embedded = false,
    this.personalInfoRoute = AppRoutes.personalInfo,
  });

  final bool embedded;
  final String personalInfoRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    final content = ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, embedded ? 100 : 20),
      children: [
        profileAsync.when(
          data: (profile) => _ProfileHeader(
            fullName: profile?.fullName ?? 'Usuario',
            email: profile?.email ?? 'Sin correo',
            jobTitle: profile?.jobTitle ?? '',
            initials: profile?.initials ?? 'NA',
            onEditAvatar: () =>
                _showSnackBar(context, 'Actualizar foto disponible pronto.'),
          ),
          loading: () => const _ProfileHeader.loading(),
          error: (_, __) => _ProfileHeader(
            fullName: 'Usuario',
            email: 'Sin correo',
            jobTitle: '',
            initials: 'NA',
            onEditAvatar: () =>
                _showSnackBar(context, 'Actualizar foto disponible pronto.'),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Cuenta'),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Informacion personal',
          subtitle: 'Edita tu nombre, telefono o cargo',
          onTap: () {
            context.push(personalInfoRoute);
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Preferencia'),
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Modo Oscuro',
          subtitle: 'Cambia la apariencia del sistema',
          onTap: () {
            _showSnackBar(context, 'Modo oscuro en desarrollo.');
          },
        ),
        _SettingsTile(
          icon: Icons.language,
          title: 'Lenguaje',
          subtitle: 'Selecciona tu idioma preferido',
          onTap: () {
            _showSnackBar(context, 'Cambio de lenguaje en desarrollo.');
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Soporte'),
        _SettingsTile(
          icon: Icons.fingerprint,
          title: 'Huella Dactilar',
          subtitle: 'Configura biometria para ingresar',
          onTap: () {
            _showSnackBar(context, 'Huella dactilar en desarrollo.');
          },
        ),
        const SizedBox(height: 24),
        OutlinedDarkButton(
          text: 'Cerrar sesion',
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (!context.mounted) return;
            context.go(AppRoutes.login);
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
  const _ProfileHeader({
    required this.onEditAvatar,
    this.fullName = '',
    this.email = '',
    this.jobTitle = '',
    this.initials = 'NA',
  });

  const _ProfileHeader.loading({this.onEditAvatar})
    : fullName = 'Cargando...',
      email = '',
      jobTitle = '',
      initials = 'NA';

  final VoidCallback? onEditAvatar;
  final String fullName;
  final String email;
  final String jobTitle;
  final String initials;

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
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
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
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: AppColors.grey)),
                const SizedBox(height: 4),
                if (jobTitle.isNotEmpty)
                  Text(
                    jobTitle,
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
