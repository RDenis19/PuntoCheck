import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/presentation/superadmin/mock/organizations_mock.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_kpi_card.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_organization_card.dart';
import 'package:puntocheck/presentation/superadmin/widgets/sa_section_title.dart';

class SuperAdminHomeView extends StatelessWidget {
  const SuperAdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final totalOrgs = mockOrganizations.length;
    final totalEmployees = mockOrganizations.fold<int>(
      0,
      (total, org) => total + org.empleados,
    );
    final totalActive = mockOrganizations.fold<int>(
      0,
      (total, org) => total + org.activosHoy,
    );
    final promedioGlobal =
        mockOrganizations.fold<double>(
          0,
          (total, org) => total + org.promedioAsistencia,
        ) /
        totalOrgs;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildKpiSection(
                totalOrgs,
                totalEmployees,
                totalActive,
                promedioGlobal,
              ),
              SaSectionTitle(
                title: 'Organizaciones recientes',
                action: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRouter.superAdminOrganizaciones,
                  ),
                  child: const Text('Ver todas'),
                ),
              ),
              ...mockOrganizations
                  .map(
                    (org) => SaOrganizationCard(
                      organization: org,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.superAdminOrganizacionDetalle,
                        arguments: org,
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.security, color: AppColors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // TODO(backend): cargar los datos del super admin autenticado (nombre/foto).
                Text(
                  'Hola Super Admin!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Panel global de PuntoCheck',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // TODO(backend): abrir centro de notificaciones globales.
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

  Widget _buildKpiSection(
    int totalOrgs,
    int totalEmployees,
    int totalActive,
    double promedioGlobal,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDark,
            AppColors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          SaKpiCard(
            label: 'Organizaciones',
            value: '$totalOrgs',
            icon: Icons.apartment_outlined,
          ),
          SaKpiCard(
            label: 'Empleados totales',
            value: '$totalEmployees',
            icon: Icons.people_outline,
          ),
          SaKpiCard(
            label: 'Activos hoy',
            value: '$totalActive',
            icon: Icons.flash_on_outlined,
          ),
          SaKpiCard(
            label: 'Promedio global asistencia',
            value: '${promedioGlobal.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_outline,
          ),
          // TODO(backend): traer KPIs reales desde endpoint agregado (no calcular en cliente).
        ],
      ),
    );
  }
}




