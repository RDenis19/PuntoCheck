import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_dashboard_header.dart';
import 'package:puntocheck/presentation/admin/widgets/admin_quick_action_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/auth_provider.dart';
import 'package:puntocheck/providers/admin_provider.dart';

class AdminHomeView extends ConsumerWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    
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

    return SafeArea(
      child: ListView(
        children: [
          _buildHeader(context, ref),
          AdminDashboardHeader(
            title: 'Panel de Administración',
            subtitle: 'Gestión empresarial',
            stats: stats,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Acciones rápidas',
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
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.adminNuevoEmpleado,
                  ),
                ),
                AdminQuickActionButton(
                  icon: Icons.people_outline,
                  title: 'Empleados',
                  subtitle: 'Gestionar empleados',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.adminEmpleadosList,
                  ),
                ),
                AdminQuickActionButton(
                  icon: Icons.map_outlined,
                  title: 'Ubicación',
                  subtitle: 'Ver empleados en mapa',
                  onTap: () {
                    // TODO(backend): conectar con el módulo de mapa en tiempo real.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mapa en desarrollo (mock).'),
                      ),
                    );
                  },
                ),
                AdminQuickActionButton(
                  icon: Icons.download_outlined,
                  title: 'Descargar Reportes',
                  subtitle: 'Reportes de asistencia',
                  onTap: () {
                    // TODO(backend): reutilizar el flujo de reportes ya implementado.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Descarga de reportes (mock).'),
                      ),
                    );
                  },
                ),
                AdminQuickActionButton(
                  icon: Icons.campaign_outlined,
                  title: 'Anuncios',
                  subtitle: 'Gestionar anuncios',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.adminAnuncios),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundDark, Color(0xFF02101E)],
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
                  data: (profile) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${profile?.fullName ?? 'Admin'}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile?.jobTitle ?? 'Administrador'} · ${DateTime.now().toString().split(' ')[0]}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  loading: () => const Text('Cargando...', style: TextStyle(color: Colors.white)),
                  error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // TODO(backend): abrir centro de notificaciones del administrador.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notificaciones (mock).')),
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
}



