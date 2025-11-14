import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/frontend/vistas/admin/widgets/admin_dashboard_header.dart';
import 'package:puntocheck/frontend/vistas/admin/widgets/admin_module_tile.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      const DashboardStat(label: 'Empleados', value: '24'),
      const DashboardStat(label: 'Activos hoy', value: '18'),
      const DashboardStat(label: 'Promedio', value: '95%'),
    ];

    final modules = [
      _ModuleData(
        title: 'Nuevo Empleado',
        subtitle: 'Registrar nuevo empleado',
        icon: Icons.person_add_alt,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminNuevoEmpleado),
      ),
      _ModuleData(
        title: 'Ubicación de Empleados',
        subtitle: 'Ver ubicación en tiempo',
        icon: Icons.map_outlined,
        onTap: () {
          // TODO(backend): integrar mapa en tiempo real para monitorear ubicaciones.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mapa en desarrollo (mock).')),
          );
        },
      ),
      _ModuleData(
        title: 'Empleados',
        subtitle: 'Gestionar empleados',
        icon: Icons.people_outline,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminEmpleadosList),
      ),
      _ModuleData(
        title: 'Descargar Reportes',
        subtitle: 'Reportes de asistencia',
        icon: Icons.download_outlined,
        onTap: () {
          // TODO(backend): generar PDF/Excel desde el backend con métricas de asistencia.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descarga de reportes (mock).')),
          );
        },
      ),
      _ModuleData(
        title: 'Establecer Horario',
        subtitle: 'Configurar jornadas',
        icon: Icons.schedule_outlined,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminHorario),
      ),
      _ModuleData(
        title: 'Anuncios',
        subtitle: 'Comunicados generales',
        icon: Icons.campaign_outlined,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminAnuncios),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              AdminDashboardHeader(
                title: 'Panel de Administración',
                subtitle: 'Gestión empresarial',
                stats: stats,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Módulos Administrativos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRouter.adminAparienciaApp,
                        );
                      },
                      icon: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modules.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (_, index) {
                    final module = modules[index];
                    return AdminModuleTile(
                      title: module.title,
                      subtitle: module.subtitle,
                      icon: module.icon,
                      onTap: module.onTap,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryRed,
            child: Icon(Icons.admin_panel_settings, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hola, Ana Ramirez!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Viernes, 31 de Octubre 2025',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                // TODO(backend): cargar datos del admin autenticado (nombre, foto, fecha actual).
                Text(
                  'Panel actualizado hace 5 min',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO(backend): abrir centro de notificaciones del administrador.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones (mock).')),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleData {
  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}
