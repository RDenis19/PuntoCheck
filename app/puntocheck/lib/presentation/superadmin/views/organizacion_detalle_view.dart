import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/organization_model.dart';
import 'package:puntocheck/models/profile_model.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/outlined_dark_button.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Detalle de organizacion para Super Admin.
/// Muestra branding, configuracion y estadisticas vivas.
class OrganizacionDetalleView extends ConsumerWidget {
  const OrganizacionDetalleView({super.key, required this.organization});

  final Organization? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (organization == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: Text('Organizacion no encontrada')),
      );
    }

    final statsAsync = ref.watch(
      organizationDashboardStatsProvider(organization!.id),
    );
    final employeesAsync = ref.watch(
      organizationEmployeesProvider(organization!.id),
    );

    return Scaffold(
      appBar: _appBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Header(organization: organization!),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => _StatsSection(stats: stats),
            loading: () => const _StatsSection(isLoading: true),
            error: (_, __) => const _StatsSection(hasError: true),
          ),
          employeesAsync.when(
            data: (employees) => _EmployeesSection(
              employees: employees,
              onViewAll: () => _showEmployeesSheet(context, employees),
            ),
            loading: () => const _EmployeesSection(isLoading: true),
            error: (_, __) =>
                const _EmployeesSection(hasError: true, employees: []),
          ),
          _BrandingCard(organization: organization!),
          _ConfigCard(organization: organization!),
          _MetaCard(organization: organization!),
          _Actions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('Detalle de organizacion'),
      centerTitle: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.black),
    );
  }

  void _showEmployeesSheet(BuildContext context, List<Profile> employees) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Empleados de la organizacion',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryRed.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          emp.initials,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(emp.fullName ?? 'Sin nombre'),
                      subtitle: Text(emp.email ?? 'Sin correo'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (organization.status) {
      OrgStatus.activa => AppColors.successGreen,
      OrgStatus.prueba => AppColors.warningOrange,
      OrgStatus.suspendida => AppColors.primaryRed,
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
          _Logo(organization: organization),
          const SizedBox(height: 12),
          Text(
            organization.name,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (organization.contactEmail != null)
            Text(
              organization.contactEmail!,
              style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _Chip(text: organization.status.name, color: statusColor),
              _Chip(text: 'ID ${organization.id}', color: AppColors.accentGold),
              _Chip(
                text: 'Creada ${_formatDate(organization.createdAt)}',
                color: Colors.white,
                textColor: AppColors.backgroundDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Logo extends StatelessWidget {
  const _Logo({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor(organization.brandColor);
    if (organization.logoUrl == null || organization.logoUrl!.isEmpty) {
      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              brandColor.withValues(alpha: 0.2),
              brandColor.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            organization.name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(organization.logoUrl!, fit: BoxFit.cover),
    );
  }

  Color _brandColor(String hex) {
    final clean = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    this.stats,
    this.isLoading = false,
    this.hasError = false,
  });

  final OrganizationDashboardSnapshot? stats;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.analytics_outlined, color: AppColors.primaryRed),
                  SizedBox(width: 8),
                  Text(
                    'Estadisticas de la organizacion',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasError)
                _Warning(
                  text:
                      'No pudimos cargar estadisticas ahora. Intenta nuevamente.',
                )
              else
                Row(
                  children: [
                    _StatCard(
                      label: 'Empleados',
                      value: stats?.totalEmployees.toString() ?? '--',
                      isLoading: isLoading,
                    ),
                    _StatCard(
                      label: 'Activos hoy',
                      value: stats?.activeToday.toString() ?? '--',
                      isLoading: isLoading,
                    ),
                    _StatCard(
                      label: 'Asistencia',
                      value: stats != null
                          ? '${stats!.attendanceAverage}%'
                          : '--',
                      isLoading: isLoading,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeesSection extends StatelessWidget {
  const _EmployeesSection({
    this.employees = const [],
    this.isLoading = false,
    this.hasError = false,
    this.onViewAll,
  });

  final List<Profile> employees;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.backgroundDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Empleados (${employees.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: hasError ? null : onViewAll,
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasError)
                const _Warning(
                  text:
                      'No pudimos cargar los empleados. Intenta nuevamente mas tarde.',
                )
              else if (isLoading)
                Column(
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (employees.isEmpty)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_off_outlined,
                        color: AppColors.black.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sin empleados registrados.',
                      style: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: employees.take(5).map((emp) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryRed.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          emp.initials,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        emp.fullName ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                      subtitle: Text(emp.email ?? 'Sin correo'),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor(organization.brandColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personalizacion',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color principal: ${organization.brandColor}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        Text(
                          'Logo: ${organization.logoUrl?.isNotEmpty == true ? 'Cargado' : 'No cargado'}',
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _brandColor(String hex) {
    final clean = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryRed;
    }
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuracion critica de asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              _ConfigRow(
                label: 'Minutos de tolerancia',
                value: '${organization.configToleranceMinutes} minutos',
              ),
              _ConfigRow(
                label: 'Requiere foto',
                value: organization.configRequirePhoto ? 'Si' : 'No',
              ),
              _ConfigRow(
                label: 'Geolocalizacion',
                value: 'Radio ${organization.configGeofenceRadius}m',
              ),
              _ConfigRow(
                label: 'Zona horaria',
                value: organization.configTimezone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contacto y metadata',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.backgroundDark,
                ),
              ),
              const SizedBox(height: 12),
              _ConfigRow(
                label: 'Correo',
                value: organization.contactEmail ?? 'N/A',
              ),
              _ConfigRow(label: 'ID interno', value: organization.id),
              _ConfigRow(
                label: 'Fecha de alta',
                value:
                    '${organization.createdAt.day}/${organization.createdAt.month}/${organization.createdAt.year}',
              ),
              _ConfigRow(
                label: 'Plan activo',
                value: 'Pendiente de integracion',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          OutlinedDarkButton(
            text: 'Entrar como Admin',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Impersonacion disponible al conectar backend.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Cambiar estado',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Accion disponible cuando exista API.'),
                ),
              );
            },
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

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
          color: textColor ?? color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.black.withValues(alpha: 0.02),
            border: Border.all(color: AppColors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.black.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              if (isLoading)
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.backgroundDark,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
