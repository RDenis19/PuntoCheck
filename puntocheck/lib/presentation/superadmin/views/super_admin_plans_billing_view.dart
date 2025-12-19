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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: handleRefresh,
          child: dashboardAsync.when(
            data: (dashboard) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const _Header(),
                const SizedBox(height: 24),
                _MetricGrid(data: dashboard),
                const SizedBox(height: 32),
                _PlanSection(
                  plansAsync: plansAsync,
                  isSaving: planEditorState.isLoading,
                  onCreate: () => _openCreatePlanDialog(context, ref),
                  onToggleActive: (plan) => ref
                      .read(planEditorControllerProvider.notifier)
                      .updatePlan(plan.id, {'activo': !(plan.activo ?? true)}),
                  onEditPrice: (plan) =>
                      _openEditPriceDialog(context, ref, plan),
                  onDelete: (plan) => _confirmDeletePlan(context, ref, plan),
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 80),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: AppColors.neutral700,
                  ),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar la información'),
                  TextButton(
                    onPressed: handleRefresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS DE DIÁLOGOS (LÓGICA PRESERVADA) ---

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
      showAppSnack(context, 'Error: $e', isError: true);
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(planEditorControllerProvider.notifier).deletePlan(plan.id);
    }
  }
}

// --- COMPONENTES VISUALES ---

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Planes y Facturación',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.neutral900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Control centralizado de planes y validación de pagos.',
          style: TextStyle(color: AppColors.neutral700, fontSize: 15),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.attach_money,
              label: 'Ingresos mes',
              value: '\$${data.monthlyRevenue.toStringAsFixed(2)}',
              gradient: [const Color(0xFFE0262F), const Color(0xFFB71C1C)],
            ),
            _MetricCard(
              width: width,
              icon: Icons.workspace_premium_outlined,
              label: 'Planes activos',
              value: '${data.plans.length}',
              gradient: [const Color(0xFF424242), const Color(0xFF212121)],
            ),
            _MetricCard(
              width: width,
              icon: Icons.receipt_long_outlined,
              label: 'Pagos pendientes',
              value: '${data.pendingPaymentsCount}',
              gradient: [const Color(0xFFF57C00), const Color(0xFFE65100)],
            ),
            _MetricCard(
              width: width,
              icon: Icons.pause_circle_outline,
              label: 'Org. pausadas',
              value: '${data.inactiveOrganizations}',
              gradient: [const Color(0xFF757575), const Color(0xFF616161)],
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
    required this.gradient,
  });
  final IconData icon;
  final String label;
  final String value;
  final double width;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
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
  final Future<void> Function(PlanesSuscripcion) onToggleActive;
  final Future<void> Function(PlanesSuscripcion) onEditPrice;
  final Future<void> Function(PlanesSuscripcion) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Planes de suscripción',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            TextButton.icon(
              onPressed: isSaving ? null : onCreate,
              icon: const Icon(Icons.add, color: AppColors.primaryRed),
              label: const Text(
                'Crear plan',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        plansAsync.when(
          data: (plans) => Column(
            children: plans
                .map(
                  (p) => _PlanCard(
                    plan: p,
                    isSaving: isSaving,
                    onToggleActive: () => onToggleActive(p),
                    onEditPrice: () => onEditPrice(p),
                    onDelete: () => onDelete(p),
                  ),
                )
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.primaryRed,
              ),
            ),
            title: Text(
              plan.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '\$${plan.precioMensual.toStringAsFixed(2)} / mes',
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: _StatusChip(isActive: isActive),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FeatureIcon(Icons.people_outline, '${plan.maxUsuarios}'),
                _FeatureIcon(Icons.storefront, '${plan.maxSucursales}'),
                _FeatureIcon(
                  Icons.cloud_outlined,
                  '${plan.almacenamientoGb}GB',
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: isSaving ? null : onToggleActive,
                      icon: Icon(
                        isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                    IconButton(
                      onPressed: isSaving ? null : onEditPrice,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blueGrey,
                      ),
                    ),
                    IconButton(
                      onPressed: isSaving ? null : onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureIcon(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral700),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
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
    final resColor =
        color ??
        (isActive ?? true ? AppColors.successGreen : AppColors.warningOrange);
    final resLabel = label ?? (isActive ?? true ? 'Activo' : 'Pausado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: resColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: resColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            resLabel.toUpperCase(),
            style: TextStyle(
              color: resColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;
  final void Function(PagosSuscripciones) onDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pagos y validaciones',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),
        DropdownButton<EstadoPago?>(
          value: estadoFilter,
          hint: const Text('Todos los estados'),
          isExpanded: true,
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
          ],
        ),
        const SizedBox(height: 12),
        paymentsAsync.when(
          data: (payments) {
            final filtered = estadoFilter == null
                ? payments
                : payments.where((p) => p.estado == estadoFilter).toList();
            if (filtered.isEmpty)
              return const EmptyState(
                title: 'Sin movimientos',
                message: 'No hay pagos con este criterio.',
                icon: Icons.receipt_long,
              );
            return Column(
              children: filtered
                  .map(
                    (p) => _PaymentTile(
                      pago: p,
                      planName: planNames[p.planId],
                      orgName: orgNames[p.organizacionId],
                      isValidating: isValidating,
                      onTap: () => onDetails(p),
                      onApprove: () => onApprove(p.id),
                      onReject: () => onReject(p.id),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
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
    final color = status == EstadoPago.aprobado
        ? AppColors.successGreen
        : (status == EstadoPago.rechazado
              ? AppColors.errorRed
              : AppColors.warningOrange);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.neutral100,
          child: Icon(Icons.receipt_outlined, color: AppColors.neutral700),
        ),
        title: Text(
          '\$${pago.monto.toStringAsFixed(2)} - ${planName ?? 'Plan'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          orgName ?? 'Org ID: ${pago.organizacionId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: status == EstadoPago.pendiente
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: isValidating ? null : onReject,
                    icon: const Icon(Icons.close, color: AppColors.errorRed),
                  ),
                  IconButton(
                    onPressed: isValidating ? null : onApprove,
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              )
            : _StatusChip(color: color, label: status.value),
      ),
    );
  }
}

// --- DETALLES DE PAGO ---

void _openPaymentDetail(
  BuildContext context,
  WidgetRef ref,
  PagosSuscripciones pago,
  Map<String, String> planNames,
  Map<String, String> orgNames,
  bool isProcessing,
) {
  final plan = planNames[pago.planId] ?? 'Plan';
  final org = orgNames[pago.organizacionId] ?? 'Org';
  final status = pago.estado ?? EstadoPago.pendiente;
  final statusColor = status == EstadoPago.aprobado
      ? AppColors.successGreen
      : (status == EstadoPago.rechazado
            ? AppColors.errorRed
            : AppColors.warningOrange);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primaryRed,
                size: 30,
              ),
              _StatusChip(color: statusColor, label: status.value),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
          ),
          Text(
            '\$${pago.monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Organización', value: org),
                const Divider(),
                _DetailRow(
                  label: 'Referencia',
                  value: pago.referenciaBancaria ?? 'N/D',
                ),
                const Divider(),
                _DetailRow(
                  label: 'Fecha',
                  value:
                      pago.creadoEn?.toLocal().toString().split(' ').first ??
                      'N/D',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (status == EstadoPago.pendiente)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await ref
                                .read(
                                  paymentValidationControllerProvider.notifier,
                                )
                                .reject(pago.id);
                            Navigator.pop(context);
                          },
                    child: const Text(
                      'Rechazar',
                      style: TextStyle(color: AppColors.errorRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await ref
                                .read(
                                  paymentValidationControllerProvider.notifier,
                                )
                                .approve(pago.id);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aprobar Pago'),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nuevo Plan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Nombre del Plan',
                controller: nameController,
                hint: 'Ej. Pro',
              ),
              _LabeledField(
                label: 'Precio',
                controller: priceController,
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
              _LabeledField(
                label: 'Usuarios',
                controller: usuariosController,
                hint: '100',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final plan = PlanesSuscripcion(
                    id: 'plan-${DateTime.now().millisecondsSinceEpoch}',
                    nombre: nameController.text.isEmpty
                        ? 'Plan Nuevo'
                        : nameController.text,
                    maxUsuarios: int.tryParse(usuariosController.text) ?? 1,
                    maxSucursales: int.tryParse(sucursalesController.text) ?? 1,
                    almacenamientoGb: int.tryParse(storageController.text) ?? 1,
                    precioMensual: double.tryParse(priceController.text) ?? 0.0,
                    activo: true,
                    tieneApiAccess: false,
                    funcionesAvanzadas: const {},
                  );
                  Navigator.pop(context, plan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPriceDialog extends StatelessWidget {
  const _EditPriceDialog({required this.plan});
  final PlanesSuscripcion plan;
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: plan.precioMensual.toStringAsFixed(2),
    );
    return AlertDialog(
      title: const Text('Editar Precio'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Nuevo precio mensual'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, double.tryParse(controller.text)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
