import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/models/registros_asistencia.dart';

/// Vista de soporte y auditoría (nivel 3).
/// Conecta logs recientes vía OperationsService (RLS decide alcance) y expone cierre de sesión.
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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supportRecentAttendanceProvider);
          await ref.read(supportRecentAttendanceProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Header(),
            const SizedBox(height: 14),
            const _QuickActions(),
            const SizedBox(height: 18),
            const _TicketsCard(),
            const SizedBox(height: 12),
            _LogsCard(logsAsync: logsAsync),
            const SizedBox(height: 16),
            _LogoutCard(isSigningOut: isSigningOut, onLogout: handleLogout),
            const SizedBox(height: 32),
          ],
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
      children: const [
        Text(
          'Soporte y auditoría',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Acceso nivel 3 para diagnóstico y logs',
          style: TextStyle(color: AppColors.neutral700),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _ActionCard(
              icon: Icons.receipt_long_outlined,
              label: 'Auditoría',
              badge: 'Logs pendientes',
            ),
            SizedBox(width: 10),
            _ActionCard(
              icon: Icons.support_agent,
              label: 'Tickets',
              badge: '0 asignados',
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            _ActionCard(
              icon: Icons.verified_user_outlined,
              label: 'Seguridad',
              badge: '2FA activo',
            ),
            SizedBox(width: 10),
            _ActionCard(
              icon: Icons.backup_outlined,
              label: 'Backups',
              badge: 'Configurar',
            ),
          ],
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
  });

  final IconData icon;
  final String label;
  final String badge;

  @override
  Widget build(BuildContext context) {
    const base = AppColors.primaryRed;
    const badgeBg = AppColors.primaryRedDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryRedDark),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2D000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketsCard extends StatelessWidget {
  const _TicketsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Tickets y soporte',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: 10),
        EmptyState(
          title: 'Sin tickets asignados',
          message:
              'Cuando lleguen solicitudes de soporte nivel 3, se verán aquí.',
          icon: Icons.headset_mic,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logs y auditoría',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 10),
        logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const EmptyState(
                title: 'Sin logs recientes',
                message:
                    'Cuando se registren marcaciones o eventos aparecerán aquí.',
                icon: Icons.list_alt,
              );
            }
            final formatter = DateFormat('dd/MM HH:mm');
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: Column(
                children: logs
                    .take(5)
                    .map(
                      (log) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.infoBlue.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.infoBlue,
                          ),
                        ),
                        title: Text(
                          log.tipoRegistro ?? 'Registro',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral900,
                          ),
                        ),
                        subtitle: Text(
                          '${log.perfilId} • ${formatter.format(log.fechaHoraMarcacion ?? DateTime.now())}',
                          style: const TextStyle(color: AppColors.neutral700),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            'No se pudo cargar logs: $error',
            style: const TextStyle(color: AppColors.errorRed),
          ),
        ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.isSigningOut, required this.onLogout});

  final bool isSigningOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuenta y sesión',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cierra sesión.',
            style: TextStyle(color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Cerrar sesión',
            isLoading: isSigningOut,
            enabled: !isSigningOut,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
