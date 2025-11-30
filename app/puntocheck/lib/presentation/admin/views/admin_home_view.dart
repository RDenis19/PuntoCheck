import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_dashboard_header.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_quick_action_button.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class AdminHomeView extends ConsumerWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final profileAsync = ref.watch(profileProvider);
    final organizationAsync = ref.watch(currentOrganizationProvider);

    final stats = statsAsync.when(
      data: (data) => [
        DashboardStat(label: 'Empleados', value: '${data['employees']}'),
        DashboardStat(label: 'Activos hoy', value: '${data['active_shifts']}'),
        DashboardStat(label: 'Atrasos', value: '${data['late_arrivals']}'),
      ],
      loading: () => const [
        DashboardStat(label: 'Empleados', value: '...'),
        DashboardStat(label: 'Activos hoy', value: '...'),
        DashboardStat(label: 'Atrasos', value: '...'),
      ],
      error: (_, __) => const [
        DashboardStat(label: 'Empleados', value: '--'),
        DashboardStat(label: 'Activos hoy', value: '--'),
        DashboardStat(label: 'Atrasos', value: '--'),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          children: [
            _buildHeader(context, profileAsync, organizationAsync),
            AdminDashboardHeader(
              title: 'Panel de Administracion',
              subtitle: organizationAsync.when(
                data: (org) =>
                    'Organizacion: ${org?.name ?? 'Sin organizacion'}',
                loading: () => 'Organizacion: ...',
                error: (_, __) => 'Organizacion: --',
              ),
              stats: stats,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Acciones rapidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.backgroundDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AdminQuickActionButton(
                    icon: Icons.person_add_alt,
                    title: 'Nuevo Empleado',
                    subtitle: 'Registrar nuevo empleado',
                    onTap: () => context.push(AppRoutes.adminNuevoEmpleado),
                  ),
                  AdminQuickActionButton(
                    icon: Icons.people_outline,
                    title: 'Empleados',
                    subtitle: 'Gestionar empleados',
                    onTap: () => context.push(AppRoutes.adminEmpleadosList),
                  ),
                  AdminQuickActionButton(
                    icon: Icons.map_outlined,
                    title: 'Ubicacion',
                    subtitle: 'Ver empleados en mapa',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Modulo de mapa en desarrollo.'),
                        ),
                      );
                    },
                  ),
                  AdminQuickActionButton(
                    icon: Icons.download_outlined,
                    title: 'Descargar Reportes',
                    subtitle: 'Reportes de asistencia',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Descarga de reportes disponible pronto.',
                          ),
                        ),
                      );
                    },
                  ),
                  AdminQuickActionButton(
                    icon: Icons.campaign_outlined,
                    title: 'Anuncios',
                    subtitle: 'Gestionar anuncios',
                    onTap: () => context.push(AppRoutes.adminAnuncios),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue profileAsync,
    AsyncValue organizationAsync,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            const Color(0xFFC62828), // Darker red
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.person, color: AppColors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileAsync.when(
                  data: (profile) {
                    final name = profile?.fullName ?? 'Admin';
                    final title = profile?.jobTitle ?? 'Administrador';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $name!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        organizationAsync.when(
                          data: (org) => Text(
                            '$title • ${_formatDate(org?.createdAt)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          loading: () => const Text(
                            'Cargando organizacion...',
                            style: TextStyle(color: Colors.white70),
                          ),
                          error: (_, __) => const Text(
                            'Organizacion',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Text(
                    'Cargando...',
                    style: TextStyle(color: Colors.white),
                  ),
                  error: (_, __) => const Text(
                    'Error',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Centro de notificaciones en desarrollo.'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.white,
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
