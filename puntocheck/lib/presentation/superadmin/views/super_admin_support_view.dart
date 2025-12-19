import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/registros_asistencia.dart';

class SuperAdminSupportView extends ConsumerWidget {
  const SuperAdminSupportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isSigningOut = authState.isLoading;
    final logsAsync = ref.watch(supportRecentAttendanceProvider);

    Future<void> handleLogout() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(authControllerProvider.notifier).signOut();
        messenger.showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('No se pudo cerrar sesión: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FB,
      ), // Fondo neutro para resaltar tarjetas
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(supportRecentAttendanceProvider);
            await ref.read(supportRecentAttendanceProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              const _Header(),
              const SizedBox(height: 24),
              const _QuickActions(),
              const SizedBox(height: 32),
              const _SectionTitle(
                title: 'Atención Técnica',
                icon: Icons.headset_mic_outlined,
              ),
              const SizedBox(height: 12),
              const EmptyState(
                title: 'Sin tickets asignados',
                message:
                    'Cuando lleguen solicitudes de nivel 3, aparecerán aquí.',
                icon: Icons.confirmation_number_outlined,
              ),
              const SizedBox(height: 32),
              const _SectionTitle(
                title: 'Logs de Sistema',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 12),
              _LogsCard(logsAsync: logsAsync),
              const SizedBox(height: 40),
              _LogoutSection(
                isSigningOut: isSigningOut,
                onLogout: handleLogout,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soporte y Auditoría',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'ACCESO NIVEL 3 • ADMINISTRADOR',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: const [
        _ActionCard(
          icon: Icons.shield_outlined,
          label: 'Seguridad',
          badge: '2FA Activo',
          colors: [Color(0xFFE0262F), Color(0xFFB71C1C)],
        ),
        _ActionCard(
          icon: Icons.history_toggle_off,
          label: 'Auditoría',
          badge: 'Logs al día',
          colors: [Color(0xFF424242), Color(0xFF212121)],
        ),
        _ActionCard(
          icon: Icons.cloud_done_outlined,
          label: 'Backups',
          badge: 'Configurado',
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        _ActionCard(
          icon: Icons.forum_outlined,
          label: 'Tickets',
          badge: '0 Pendientes',
          colors: [Color(0xFFF57C00), Color(0xFFE65100)],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.badge,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String badge;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                badge,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }
}

class _LogsCard extends StatelessWidget {
  const _LogsCard({required this.logsAsync});
  final AsyncValue<List<RegistrosAsistencia>> logsAsync;

  @override
  Widget build(BuildContext context) {
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyState(
            title: 'Logs limpios',
            message: 'No hay eventos recientes registrados en el sistema.',
            icon: Icons.rule_folder_outlined,
          );
        }
        final formatter = DateFormat('dd MMM, HH:mm');
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: logs.take(5).map((log) {
              final isLast =
                  logs.indexOf(log) == 4 ||
                  logs.indexOf(log) == logs.length - 1;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      log.tipoRegistro ?? 'Evento de Sistema',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'ID: ${log.perfilId.substring(0, 8)}... • ${formatter.format(log.fechaHoraMarcacion)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 60, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error al cargar logs',
          style: TextStyle(color: AppColors.errorRed),
        ),
      ),
    );
  }
}

class _LogoutSection extends StatelessWidget {
  const _LogoutSection({required this.isSigningOut, required this.onLogout});
  final bool isSigningOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSigningOut ? null : onLogout,
              icon: isSigningOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              label: Text(
                isSigningOut ? 'CERRANDO...' : 'CERRAR SESIÓN',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
