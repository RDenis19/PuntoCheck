import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:puntocheck/models/organizaciones.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/models/registros_asistencia.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/planes_suscripcion.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/shared/widgets/app_snackbar.dart';
import 'package:puntocheck/presentation/superadmin/views/super_admin_create_admin_view.dart';

class SuperAdminOrgDetailView extends ConsumerStatefulWidget {
  final String orgId;

  const SuperAdminOrgDetailView({super.key, required this.orgId});

  @override
  ConsumerState<SuperAdminOrgDetailView> createState() =>
      _SuperAdminOrgDetailViewState();
}

class _SuperAdminOrgDetailViewState
    extends ConsumerState<SuperAdminOrgDetailView> {
  bool _showActions = false;

  void _closeActions() => setState(() => _showActions = false);

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(organizationDetailProvider(widget.orgId));
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showActions) ...[
            _MiniFab(
              icon: Icons.receipt_long,
              label: 'Pagos',
              onTap: () {
                _closeActions();
                context.push(
                  '${AppRoutes.superAdminHome}/org/${widget.orgId}/payments',
                );
              },
            ),
            const SizedBox(height: 10),
            _MiniFab(
              icon: Icons.person_add_alt_1,
              label: 'Crear admin',
              onTap: () {
                _closeActions();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SuperAdminCreateAdminView(orgId: widget.orgId),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _MiniFab(
              icon: Icons.edit,
              label: 'Editar organizacion',
              onTap: () {
                final currentOrg = orgAsync.asData?.value;
                _closeActions();
                if (currentOrg != null) {
                  showDialog(
                    context: context,
                    builder: (_) => _EditOrgDialog(org: currentOrg),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            onPressed: () => setState(() => _showActions = !_showActions),
            child: Icon(_showActions ? Icons.close : Icons.more_horiz),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('Detalle de organización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: orgAsync.when(
        data: (org) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(organizationDetailProvider(widget.orgId).future),
              ref.refresh(orgComplianceAlertsProvider(widget.orgId).future),
              ref.refresh(orgRecentAttendanceProvider(widget.orgId).future),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrgHeaderSection(org: org),
                const SizedBox(height: 16),
                _OrgStatusAndPlanSection(org: org, orgId: widget.orgId),
                const SizedBox(height: 24),
                _ComplianceSection(orgId: widget.orgId),
                const SizedBox(height: 24),
                _AttendanceSection(orgId: widget.orgId),
                const SizedBox(height: 24),
                _StaffShortcut(orgId: widget.orgId),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar la organización: $error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrgHeaderSection extends StatelessWidget {
  final Organizaciones org;

  const _OrgHeaderSection({required this.org});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                (org.razonSocial.isNotEmpty ? org.razonSocial[0] : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.razonSocial,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RUC: ${org.ruc}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
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

class _OrgStatusAndPlanSection extends ConsumerWidget {
  final Organizaciones org;
  final String orgId;

  const _OrgStatusAndPlanSection({required this.org, required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lifecycle = ref.read(
      organizationLifecycleControllerProvider.notifier,
    );

    final estado = org.estadoSuscripcion;
    final estadoLabel = estado?.name ?? estado?.toString() ?? 'SIN ESTADO';
    final dashboard = ref
        .watch(superAdminDashboardProvider)
        .maybeWhen(data: (d) => d, orElse: () => null);
    final planName = () {
      final plans = dashboard?.plans ?? [];
      final match = plans.where((p) => p.id == org.planId).toList();
      if (match.isNotEmpty) return match.first.nombre;
      if (org.planId != null) return 'Plan ${org.planId}';
      return 'Sin plan asignado';
    }();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado y suscripción',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estadoLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan actual: $planName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<EstadoSuscripcion>(
                tooltip: 'Cambiar estado de suscripción',
                onSelected: (nuevoEstado) {
                  lifecycle.updateStatus(orgId: orgId, estado: nuevoEstado);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: EstadoSuscripcion.activo,
                    child: Text('Marcar como Activo'),
                  ),
                  PopupMenuItem(
                    value: EstadoSuscripcion.prueba,
                    child: Text('Marcar como En trial'),
                  ),
                  PopupMenuItem(
                    value: EstadoSuscripcion.vencido,
                    child: Text('Marcar como Vencido'),
                  ),
                  PopupMenuItem(
                    value: EstadoSuscripcion.cancelado,
                    child: Text('Cancelar'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: AppColors.primaryRed,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Cambiar estado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
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

class _ComplianceSection extends ConsumerWidget {
  final String orgId;

  const _ComplianceSection({required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(orgComplianceAlertsProvider(orgId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cumplimiento LOE',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Riesgos y desvíos respecto a la jornada laboral, descansos y horas extras.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 12),
        alertsAsync.when(
          data: (alerts) {
            if (alerts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No se registran alertas de cumplimiento recientes. La organización está alineada con la LOE.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: alerts
                  .map((alert) => _ComplianceAlertTile(alert: alert))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'No se pudieron cargar las alertas de cumplimiento: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComplianceAlertTile extends StatelessWidget {
  final AlertasCumplimiento alert;

  const _ComplianceAlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tipo = alert.tipoIncumplimiento;
    final descripcion =
        (alert.detalleTecnico?['descripcion'] as String?) ??
        'Detalle no disponible';
    final severidad = alert.gravedad?.value ?? 'sin_severidad';
    final estado = alert.estado ?? 'pendiente';
    final fecha = alert.fechaDeteccion;

    Color badgeColor;
    switch (severidad.toLowerCase()) {
      case 'grave_legal':
      case 'alta':
        badgeColor = AppColors.errorRed;
        break;
      case 'moderada':
      case 'media':
        badgeColor = AppColors.warningOrange;
        break;
      default:
        badgeColor = AppColors.infoBlue;
    }

    final fechaStr = fecha != null
        ? '${fecha.day}/${fecha.month}/${fecha.year}'
        : 'Fecha no disponible';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: badgeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Severidad: $severidad | Estado: $estado | $fechaStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
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

class _AttendanceSection extends ConsumerWidget {
  final String orgId;

  const _AttendanceSection({required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(orgRecentAttendanceProvider(orgId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad reciente de asistencia',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Últimos registros de check-in / check-out para soporte y auditoría rápida.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 12),
        attendanceAsync.when(
          data: (registros) {
            if (registros.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Text(
                  'No hay registros de asistencia recientes para mostrar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              );
            }

            return Column(
              children: registros
                  .map((r) => _AttendanceTile(registro: r))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'No se pudo cargar la actividad reciente: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final RegistrosAsistencia registro;

  const _AttendanceTile({required this.registro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final empleadoNombre = registro.perfilId;
    final fecha = registro.fechaHoraMarcacion;
    final fechaStr =
        '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    final tipo = registro.tipoRegistro ?? 'registro';
    final esValido = registro.esValidoLegalmente ?? true;
    final dentroGeocerca = registro.estaDentroGeocerca ?? false;

    final chipLabel = esValido ? 'Valido' : 'Revisar';
    final chipColor = esValido
        ? AppColors.successGreen
        : AppColors.warningOrange;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: chipColor.withValues(alpha: 0.12),
            child: Icon(
              esValido
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: chipColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empleadoNombre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tipo | $fechaStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$chipLabel${dentroGeocerca ? '' : ' | Fuera geocerca'}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: chipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffShortcut extends StatelessWidget {
  final String orgId;

  const _StaffShortcut({required this.orgId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.push('${AppRoutes.superAdminHome}/org/$orgId/staff');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryRed.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.primaryRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ver equipo y roles de esta organización',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryRed,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditOrgDialog extends ConsumerStatefulWidget {
  const _EditOrgDialog({required this.org});

  final Organizaciones org;

  @override
  ConsumerState<_EditOrgDialog> createState() => _EditOrgDialogState();
}

class _EditOrgDialogState extends ConsumerState<_EditOrgDialog> {
  late final TextEditingController _rucCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _logoCtrl;
  PlanesSuscripcion? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _rucCtrl = TextEditingController(text: widget.org.ruc);
    _nameCtrl = TextEditingController(text: widget.org.razonSocial);
    _logoCtrl = TextEditingController(text: widget.org.logoUrl ?? '');
  }

  @override
  void dispose() {
    _rucCtrl.dispose();
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final editState = ref.watch(organizationEditControllerProvider);
    final isSaving = editState.isLoading;

    Future<void> onSave() async {
      await ref
          .read(organizationEditControllerProvider.notifier)
          .updateOrganization(
            orgId: widget.org.id,
            ruc: _rucCtrl.text.trim(),
            razonSocial: _nameCtrl.text.trim(),
            logoUrl: _logoCtrl.text.trim().isEmpty
                ? null
                : _logoCtrl.text.trim(),
            planId: _selectedPlan?.id ?? widget.org.planId,
          );
      final state = ref.read(organizationEditControllerProvider);
      if (!mounted) return;
      if (state.hasError) {
        showAppSnack(context, 'Error: ${state.error}', isError: true);
      } else {
        showAppSnack(context, 'Organización actualizada');
        Navigator.of(context).pop();
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar organización',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'RUC',
                controller: _rucCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _InputField(label: 'Razón social', controller: _nameCtrl),
              const SizedBox(height: 10),
              _InputField(
                label: 'Logo (URL)',
                controller: _logoCtrl,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              const Text(
                'Plan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 6),
              plansAsync.when(
                data: (plans) {
                  final items = plans
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p, child: Text(p.nombre)),
                      )
                      .toList();
                  final current =
                      _selectedPlan ??
                      plans.firstWhere(
                        (p) => p.id == widget.org.planId,
                        orElse: () => plans.first,
                      );
                  _selectedPlan ??= current;
                  return DropdownButtonFormField<PlanesSuscripcion>(
                    value: _selectedPlan,
                    items: items,
                    onChanged: isSaving
                        ? null
                        : (p) => setState(() => _selectedPlan = p),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.neutral100,
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Error cargando planes: $e',
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving ? null : onSave,
                      child: Text(isSaving ? 'Guardando...' : 'Guardar'),
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
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE7ECF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniFab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
