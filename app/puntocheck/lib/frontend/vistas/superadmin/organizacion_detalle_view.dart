import 'package:flutter/material.dart';
import 'package:puntocheck/core/theme/app_colors.dart';
import 'package:puntocheck/frontend/vistas/superadmin/mock/organizations_mock.dart';
import 'package:puntocheck/frontend/widgets/outlined_dark_button.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';

class OrganizacionDetalleView extends StatelessWidget {
  const OrganizacionDetalleView({super.key});

  @override
  Widget build(BuildContext context) {
    final org = ModalRoute.of(context)?.settings.arguments as MockOrganization?;
    final organization = org ?? mockOrganizations.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de organización'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _buildHeader(organization),
          _buildStats(organization),
          _buildBranding(organization),
          _buildConfigAsistencia(),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(MockOrganization organization) {
    Color statusColor = switch (organization.estado) {
      'activa' => AppColors.successGreen,
      'prueba' => AppColors.warningOrange,
      'suspendida' => AppColors.primaryRed,
      _ => AppColors.grey,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundDark,
            AppColors.black.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.white.withValues(alpha: 0.9),
            child: Text(
              organization.nombre.substring(0, 1),
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            organization.nombre,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${organization.adminNombre} · ${organization.adminEmail}',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(text: organization.estado, color: statusColor),
              const SizedBox(width: 8),
              const _Chip(text: 'Plan Pro', color: AppColors.accentGold),
            ],
          ),
          const SizedBox(height: 8),
          // TODO(backend): estado y plan deben provenir del sistema de suscripciones/tenant.
        ],
      ),
    );
  }

  Widget _buildStats(MockOrganization organization) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _StatCard(label: 'Empleados', value: '${organization.empleados}'),
          _StatCard(label: 'Activos hoy', value: '${organization.activosHoy}'),
          _StatCard(
            label: 'Promedio 30 días',
            value: '${organization.promedioAsistencia.toStringAsFixed(1)}%',
          ),
          const _StatCard(label: 'Registros este mes', value: '1,245'),
        ],
      ),
    );
  }

  Widget _buildBranding(MockOrganization organization) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Branding',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              Text('Nombre interno: ${organization.nombre}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Color principal: #EB283D'),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Logo personalizado: No cargado'),
              // TODO(backend): leer datos reales de configuración de marca por organización.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigAsistencia() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuración crítica de asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              _ConfigRow(label: 'Minutos de tolerancia', value: '5 minutos'),
              _ConfigRow(label: 'Requiere foto', value: 'Sí'),
              _ConfigRow(
                label: 'Requiere geolocalización',
                value: 'Sí (50m precisión)',
              ),
              _ConfigRow(label: 'Precisión mínima', value: '50 metros'),
              // TODO(backend): usar configuraciones reales para auditoría de cada organización.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          OutlinedDarkButton(
            text: 'Entrar como Admin',
            onPressed: () {
              // TODO(backend): iniciar flujo seguro de impersonación registrado en logs.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función de impersonar (mock).')),
              );
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Cambiar estado (Activar/Suspender)',
            onPressed: () {
              // TODO(backend): cambiar estado de la organización y notificar a administradores.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Estado actualizado (mock).')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.backgroundDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.black.withValues(alpha: 0.6)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.backgroundDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
