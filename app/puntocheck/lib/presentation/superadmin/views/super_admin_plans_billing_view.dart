import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/pagos_suscripciones.dart';
import 'package:puntocheck/models/planes_suscripcion.dart';
import 'package:puntocheck/models/super_admin_dashboard.dart';
import 'package:puntocheck/presentation/shared/widgets/app_snackbar.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SuperAdminPlansBillingView extends ConsumerStatefulWidget {
  const SuperAdminPlansBillingView({super.key});

  @override
  ConsumerState<SuperAdminPlansBillingView> createState() =>
      _SuperAdminPlansBillingViewState();
}

class _SuperAdminPlansBillingViewState
    extends ConsumerState<SuperAdminPlansBillingView> {
  EstadoPago? _estadoFilter;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(superAdminDashboardProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final planEditorState = ref.watch(planEditorControllerProvider);
    final paymentState = ref.watch(paymentValidationControllerProvider);

    final planNames = <String, String>{};
    final orgNames = <String, String>{};
    plansAsync.whenData((plans) {
      for (final plan in plans) {
        planNames[plan.id] = plan.nombre;
      }
    });
    dashboardAsync.whenData((dash) {
      for (final org in dash.organizations) {
        orgNames[org.id] = org.razonSocial;
      }
    });

    Future<void> handleRefresh() async {
      ref
        ..invalidate(superAdminDashboardProvider)
        ..invalidate(subscriptionPlansProvider)
        ..invalidate(pendingPaymentsProvider)
        ..invalidate(allPaymentsProvider);
      await ref.read(superAdminDashboardProvider.future);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: handleRefresh,
        child: dashboardAsync.when(
          data: (dashboard) => ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _Header(),
              const SizedBox(height: 18),
              _MetricGrid(data: dashboard),
              const SizedBox(height: 18),
              _PlanSection(
                plansAsync: plansAsync,
                isSaving: planEditorState.isLoading,
                onCreate: () => _openCreatePlanDialog(context, ref),
                onToggleActive: (plan) => ref
                    .read(planEditorControllerProvider.notifier)
                    .updatePlan(plan.id, {'activo': !(plan.activo ?? true)}),
                onEditPrice: (plan) => _openEditPriceDialog(context, ref, plan),
                onDelete: (plan) => _confirmDeletePlan(context, ref, plan),
              ),
              const SizedBox(height: 18),
              _PaymentsSection(
                paymentsAsync: paymentsAsync,
                planNames: planNames,
                orgNames: orgNames,
                estadoFilter: _estadoFilter,
                isValidating: paymentState.isLoading,
                onFilterChange: (value) =>
                    setState(() => _estadoFilter = value),
                onApprove: (paymentId) => ref
                    .read(paymentValidationControllerProvider.notifier)
                    .approve(paymentId),
                onReject: (paymentId) => ref
                    .read(paymentValidationControllerProvider.notifier)
                    .reject(paymentId),
                onDetails: (pago) => _openPaymentDetail(
                  context,
                  ref,
                  pago,
                  planNames,
                  orgNames,
                  paymentState.isLoading,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: AppColors.neutral700,
                ),
                const SizedBox(height: 12),
                const Text('No se pudo cargar planes y facturación'),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.neutral700),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: handleRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreatePlanDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final plan = await showDialog<PlanesSuscripcion>(
      context: context,
      builder: (_) => const _CreatePlanDialog(),
    );

    if (plan == null) return;

    try {
      await ref.read(planEditorControllerProvider.notifier).createPlan(plan);
      final state = ref.read(planEditorControllerProvider);
      if (state.hasError) {
        showAppSnack(
          context,
          'Error creando plan: ${state.error}',
          isError: true,
        );
      } else {
        showAppSnack(context, 'Plan creado correctamente');
      }
    } catch (e) {
      showAppSnack(context, 'Error creando plan: $e', isError: true);
    }
  }

  Future<void> _openEditPriceDialog(
    BuildContext context,
    WidgetRef ref,
    PlanesSuscripcion plan,
  ) async {
    final newPrice = await showDialog<double>(
      context: context,
      builder: (_) => _EditPriceDialog(plan: plan),
    );
    if (newPrice != null) {
      await ref.read(planEditorControllerProvider.notifier).updatePlan(
        plan.id,
        {'precio_mensual': newPrice},
      );
    }
  }

  Future<void> _confirmDeletePlan(
    BuildContext context,
    WidgetRef ref,
    PlanesSuscripcion plan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: Text('¿Eliminar el plan "${plan.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ref.read(planEditorControllerProvider.notifier).deletePlan(plan.id);
      final state = ref.read(planEditorControllerProvider);
      if (state.hasError) {
        showAppSnack(context, 'Error eliminando plan: ${state.error}', isError: true);
      } else {
        showAppSnack(context, 'Plan eliminado');
      }
    } catch (e) {
      showAppSnack(context, 'Error eliminando plan: $e', isError: true);
    }
  }
}

void _openPaymentDetail(
  BuildContext context,
  WidgetRef ref,
  PagosSuscripciones pago,
  Map<String, String> planNames,
  Map<String, String> orgNames,
  bool isProcessing,
) {
  final plan = planNames[pago.planId] ?? 'Plan';
  final org = orgNames[pago.organizacionId] ?? pago.organizacionId;
  final status = pago.estado ?? EstadoPago.pendiente;
  final statusColor = () {
    switch (status) {
      case EstadoPago.aprobado:
        return AppColors.successGreen;
      case EstadoPago.rechazado:
        return AppColors.errorRed;
      case EstadoPago.pendiente:
      default:
        return AppColors.warningOrange;
    }
  }();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              _StatusChip(
                color: statusColor,
                label: status.value.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Organización: $org'),
          const SizedBox(height: 6),
          Text(
            'Monto: \$${pago.monto.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (pago.referenciaBancaria != null &&
              pago.referenciaBancaria!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Referencia: ${pago.referenciaBancaria}'),
          ],
          const SizedBox(height: 6),
          Text('Comprobante: ${pago.comprobanteUrl}'),
          if (pago.creadoEn != null) ...[
            const SizedBox(height: 6),
            Text(
              'Registrado: ${pago.creadoEn!.toLocal().toString().split(' ').first}',
            ),
          ],
          if (pago.fechaValidacion != null) ...[
            const SizedBox(height: 6),
            Text(
              'Validado: ${pago.fechaValidacion!.toLocal().toString().split(' ').first}',
            ),
          ],
          if ((pago.observaciones ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Observaciones: ${pago.observaciones}'),
          ],
          const SizedBox(height: 14),
          if (status == EstadoPago.pendiente)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await ref
                                .read(
                                  paymentValidationControllerProvider.notifier,
                                )
                                .reject(pago.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.close, color: AppColors.primaryRed),
                    label: const Text(
                      'Rechazar',
                      style: TextStyle(color: AppColors.primaryRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await ref
                                .read(
                                  paymentValidationControllerProvider.notifier,
                                )
                                .approve(pago.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Planes y facturación',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Control centralizado de planes, pagos y proyecciones.',
          style: TextStyle(color: AppColors.neutral700),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final SuperAdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        icon: Icons.attach_money,
        label: 'Ingresos mes',
        value: '\$${data.monthlyRevenue.toStringAsFixed(2)}',
      ),
      _Metric(
        icon: Icons.workspace_premium_outlined,
        label: 'Planes activos',
        value: '${data.plans.length}',
      ),
      _Metric(
        icon: Icons.receipt_long_outlined,
        label: 'Pagos pendientes',
        value: '${data.pendingPaymentsCount}',
      ),
      _Metric(
        icon: Icons.pause_circle_outline,
        label: 'Org. pausadas',
        value: '${data.inactiveOrganizations}',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.map((m) => _MetricCard(metric: m)).toList(),
    );
  }
}

class _Metric {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({required this.icon, required this.label, required this.value});
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AE0262F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _PlanSection extends StatelessWidget {
  const _PlanSection({
    required this.plansAsync,
    required this.isSaving,
    required this.onCreate,
    required this.onToggleActive,
    required this.onEditPrice,
    required this.onDelete,
  });

  final AsyncValue<List<PlanesSuscripcion>> plansAsync;
  final bool isSaving;
  final VoidCallback onCreate;
  final Future<void> Function(PlanesSuscripcion plan) onToggleActive;
  final Future<void> Function(PlanesSuscripcion plan) onEditPrice;
  final Future<void> Function(PlanesSuscripcion plan) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Planes de suscripción',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: isSaving ? null : onCreate,
              icon: const Icon(Icons.add, color: AppColors.primaryRed),
              label: const Text(
                'Crear plan',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return const EmptyState(
                title: 'Sin planes publicados',
                message: 'Crea un plan para empezar a asignar organizaciones.',
                icon: Icons.workspace_premium_outlined,
              );
            }

            return Column(
              children: [
                for (final plan in plans) ...[
                  _PlanCard(
                    plan: plan,
                    isSaving: isSaving,
                    onToggleActive: () => onToggleActive(plan),
                    onEditPrice: () => onEditPrice(plan),
                    onDelete: () => onDelete(plan),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            'No se pudo cargar planes: $error',
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSaving,
    required this.onToggleActive,
    required this.onEditPrice,
    required this.onDelete,
  });

  final PlanesSuscripcion plan;
  final bool isSaving;
  final VoidCallback onToggleActive;
  final VoidCallback onEditPrice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = plan.activo ?? true;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ),
                    _StatusChip(isActive: isActive),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${plan.precioMensual.toStringAsFixed(2)} / mes | '
                  '${plan.maxUsuarios} usuarios | '
                  '${plan.maxSucursales} sucursales | '
                  '${plan.almacenamientoGb} GB',
                  style: const TextStyle(color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isActive ? 'Pausar' : 'Activar',
                  onPressed: isSaving ? null : onToggleActive,
                icon: Icon(
                  isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_fill,
                  color: isActive
                      ? AppColors.warningOrange
                      : AppColors.successGreen,
                ),
              ),
              IconButton(
                tooltip: 'Editar precio',
                onPressed: isSaving ? null : onEditPrice,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.neutral700,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: isSaving ? null : onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({this.isActive, this.color, this.label});

  final bool? isActive;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (isActive ?? true ? AppColors.successGreen : AppColors.warningOrange);
    final resolvedLabel = label ?? (isActive ?? true ? 'Activo' : 'Pausado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        resolvedLabel,
        style: TextStyle(color: resolvedColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PaymentsSection extends StatelessWidget {
  const _PaymentsSection({
    required this.paymentsAsync,
    required this.planNames,
    required this.orgNames,
    required this.estadoFilter,
    required this.isValidating,
    required this.onFilterChange,
    required this.onApprove,
    required this.onReject,
    required this.onDetails,
  });

  final AsyncValue<List<PagosSuscripciones>> paymentsAsync;
  final Map<String, String> planNames;
  final Map<String, String> orgNames;
  final EstadoPago? estadoFilter;
  final bool isValidating;
  final ValueChanged<EstadoPago?> onFilterChange;
  final Future<void> Function(String id) onApprove;
  final Future<void> Function(String id) onReject;
  final void Function(PagosSuscripciones pago) onDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pagos pendientes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.neutral900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Filtro', style: TextStyle(color: AppColors.neutral700)),
            const SizedBox(width: 10),
            DropdownButton<EstadoPago?>(
              value: estadoFilter,
              hint: const Text('Todos'),
              onChanged: onFilterChange,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(
                  value: EstadoPago.pendiente,
                  child: Text('Pendientes'),
                ),
                DropdownMenuItem(
                  value: EstadoPago.aprobado,
                  child: Text('Aprobados'),
                ),
                DropdownMenuItem(
                  value: EstadoPago.rechazado,
                  child: Text('Rechazados'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        paymentsAsync.when(
          data: (payments) {
            final filtered = estadoFilter == null
                ? payments
                : payments.where((p) => p.estado == estadoFilter).toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                title: 'Sin pagos por validar',
                message: 'Cuando se suban comprobantes aparecerán aquí.',
                icon: Icons.receipt_long_outlined,
              );
            }

            return Column(
              children: [
                for (final pago in filtered) ...[
                  _PaymentTile(
                    pago: pago,
                    planName: planNames[pago.planId],
                    orgName: orgNames[pago.organizacionId],
                    isValidating: isValidating,
                    onTap: () => onDetails(pago),
                    onApprove: () => onApprove(pago.id),
                    onReject: () => onReject(pago.id),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(
            'No se pudieron cargar pagos: $error',
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.pago,
    required this.planName,
    required this.orgName,
    required this.isValidating,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final PagosSuscripciones pago;
  final String? planName;
  final String? orgName;
  final bool isValidating;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = pago.estado ?? EstadoPago.pendiente;
    final isPending = status == EstadoPago.pendiente;
    final statusColor = () {
      switch (status) {
        case EstadoPago.aprobado:
          return AppColors.successGreen;
        case EstadoPago.rechazado:
          return AppColors.errorRed;
        case EstadoPago.pendiente:
        default:
          return AppColors.warningOrange;
      }
    }();
    final statusLabel = status.value.toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECF3)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.neutral100,
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${pago.monto.toStringAsFixed(2)} | ${planName ?? 'Plan'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Org: ${orgName ?? pago.organizacionId} | Ref: ${pago.referenciaBancaria ?? 'N/D'}',
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(color: statusColor, label: statusLabel),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPending)
              Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Rechazar',
                    onPressed: isValidating ? null : onReject,
                    icon: const Icon(Icons.close, color: AppColors.primaryRed),
                  ),
                  IconButton(
                    tooltip: 'Aprobar',
                    onPressed: isValidating ? null : onApprove,
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog();

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController(text: '0.00');
  final usuariosController = TextEditingController(text: '100');
  final sucursalesController = TextEditingController(text: '3');
  final storageController = TextEditingController(text: '10');

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    usuariosController.dispose();
    sucursalesController.dispose();
    storageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear plan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 14),
              _LabeledField(
                label: 'Nombre',
                hint: 'Ej: Plan Empresarial',
                controller: nameController,
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Precio mensual',
                hint: '0.00',
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Max. usuarios',
                hint: '100',
                controller: usuariosController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Max. sucursales',
                hint: '3',
                controller: sucursalesController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Storage (GB)',
                hint: '10',
                controller: storageController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    onPressed: () {
                      final price = double.tryParse(priceController.text);
                      final maxUsuarios = int.tryParse(usuariosController.text);
                      final maxSucursales = int.tryParse(
                        sucursalesController.text,
                      );
                      final storage = int.tryParse(storageController.text);
                      if (price == null ||
                          maxUsuarios == null ||
                          maxSucursales == null ||
                          storage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa los datos numéricos del plan'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                        return;
                      }
                      final plan = PlanesSuscripcion(
                        id: 'plan-${DateTime.now().millisecondsSinceEpoch}',
                        nombre: nameController.text.trim().isEmpty
                            ? 'Plan sin nombre'
                            : nameController.text.trim(),
                          maxUsuarios: maxUsuarios,
                          maxSucursales: maxSucursales,
                          almacenamientoGb: storage,
                          precioMensual: price,
                          activo: true,
                          tieneApiAccess: false,
                          funcionesAvanzadas: const {},
                        );
                        Navigator.of(context).pop(plan);
                      },
                      child: const Text('Crear'),
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

class _EditPriceDialog extends StatefulWidget {
  const _EditPriceDialog({required this.plan});

  final PlanesSuscripcion plan;

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late final TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.plan.precioMensual.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar precio de ${widget.plan.nombre}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Precio mensual',
              hint: '0.00',
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final parsed = double.tryParse(priceController.text);
                      Navigator.of(context).pop(parsed);
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
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
            hintText: hint,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
