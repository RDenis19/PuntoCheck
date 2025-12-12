import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/planes_suscripcion.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/admin/widgets/empty_state.dart';
import 'package:puntocheck/presentation/admin/widgets/async_error_view.dart';
import 'package:puntocheck/presentation/common/widgets/app_snackbar.dart';
import 'package:puntocheck/presentation/common/widgets/status_chip.dart';
import 'package:puntocheck/models/pagos_suscripciones.dart';

class OrgAdminPaymentsView extends ConsumerStatefulWidget {
  const OrgAdminPaymentsView({super.key});

  @override
  ConsumerState<OrgAdminPaymentsView> createState() => _OrgAdminPaymentsViewState();
}

class _OrgAdminPaymentsViewState extends ConsumerState<OrgAdminPaymentsView> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(orgAdminPaymentsProvider);
    final orgAsync = ref.watch(orgAdminOrganizationProvider);
    final plansAsync = ref.watch(_plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos y suscripciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : () => _showCreateDialog(context, orgAsync),
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(error: e),
        data: (org) {
          final currentPlan = _findPlan(plansAsync, org.planId);
          return paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AsyncErrorView(
              error: e,
              onRetry: () => ref.invalidate(orgAdminPaymentsProvider),
            ),
            data: (list) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PlanCard(
                    orgName: org.razonSocial,
                    planName: _resolvePlanName(plansAsync, null, org.planId),
                    estado: org.estadoSuscripcion?.value ?? 'sin_estado',
                    fechaFin: org.fechaFinSuscripcion,
                    plan: currentPlan,
                    logoUrl: org.logoUrl,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Historial de pagos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin pagos registrados',
                      subtitle: 'Registra un pago para esta organización.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final pago = list[index];
                        final planName = _resolvePlanName(plansAsync, null, pago.planId);
                        final estadoLabel = pago.estado?.value ?? 'pendiente';
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.neutral200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
                              child: const Icon(Icons.receipt_long, color: AppColors.primaryRed),
                            ),
                            title: Text(
                              planName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Monto: ${pago.monto.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppColors.neutral700),
                                ),
                                if (pago.creadoEn != null)
                                  Text(
                                    'Registrado: ${_fmtDate(pago.creadoEn!)}',
                                    style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: StatusChip(
                              label: estadoLabel,
                              isPositive: estadoLabel.toLowerCase() == 'aprobado',
                            ),
                            onTap: () => _showPaymentDetail(context, pago, planName),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    AsyncValue orgAsync,
  ) async {
    final org = orgAsync.asData?.value;
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final comprobanteCtrl = TextEditingController();
    final planCtrl = TextEditingController(text: org?.planId ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar pago'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: planCtrl,
                decoration: const InputDecoration(
                  labelText: 'Plan ID',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
              ),
              TextField(
                controller: comprobanteCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL comprobante',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referencia bancaria',
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || org == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(paymentsServiceProvider).createPayment(
            orgId: org.id,
            planId: planCtrl.text.trim().isEmpty ? (org.planId ?? '') : planCtrl.text.trim(),
            monto: amount,
            comprobanteUrl: comprobanteCtrl.text.trim(),
            referencia: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
          );
      ref.invalidate(orgAdminPaymentsProvider);
      if (!mounted) return;
      showAppSnackBar(context, 'Pago registrado en estado pendiente', success: true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPaymentDetail(BuildContext context, PagosSuscripciones pago, String planName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Text(
                    'Pago ${pago.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Plan', planName),
              _detailRow('Monto', pago.monto.toStringAsFixed(2)),
              _detailRow('Estado', pago.estado?.value ?? 'pendiente'),
              if (pago.creadoEn != null)
                _detailRow('Registrado', _fmtDate(pago.creadoEn!)),
              if (pago.referenciaBancaria != null && pago.referenciaBancaria!.isNotEmpty)
                _detailRow('Referencia', pago.referenciaBancaria!),
              const SizedBox(height: 12),
              if (pago.comprobanteUrl.isNotEmpty)
                Text(
                  'Comprobante: ${pago.comprobanteUrl}',
                  style: const TextStyle(color: AppColors.neutral700),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String orgName;
  final String planName;
  final String estado;
  final DateTime? fechaFin;
  final PlanesSuscripcion? plan;
  final String? logoUrl;

  const _PlanCard({
    required this.orgName,
    required this.planName,
    required this.estado,
    required this.fechaFin,
    this.plan,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                backgroundImage: (logoUrl != null && logoUrl!.isNotEmpty) ? NetworkImage(logoUrl!) : null,
                child: (logoUrl == null || logoUrl!.isEmpty)
                    ? const Icon(Icons.apartment_rounded, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  orgName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              _PlanStatusPill(status: estado),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text('Plan: $planName', style: const TextStyle(color: Colors.white)),
            ],
          ),
          if (fechaFin != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_available_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Vence: ${_fmtDate(fechaFin!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanInfoChip(
                icon: Icons.people_alt_outlined,
                label: '${plan?.maxUsuarios ?? '--'} usuarios',
              ),
              _PlanInfoChip(
                icon: Icons.store_mall_directory_outlined,
                label: '${plan?.maxSucursales ?? '--'} sucursales',
              ),
              _PlanInfoChip(
                icon: Icons.cloud_outlined,
                label: '${plan?.almacenamientoGb ?? '--'} GB',
              ),
              _PlanInfoChip(
                icon: Icons.payments_outlined,
                label: plan != null
                    ? '\$${plan!.precioMensual.toStringAsFixed(2)}/mes'
                    : 'Consultar plan',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Gestiona tus planes, pagos y cambios de suscripción aquí.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlanInfoChip extends StatelessWidget {
  const _PlanInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatusPill extends StatelessWidget {
  const _PlanStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isActive = normalized.contains('activ');
    final bg = isActive ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.12);
    final border = isActive ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.25);
    final fg = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.pause_circle_outline, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            status.isEmpty ? 'sin estado' : status,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.neutral900),
          ),
        ),
      ],
    ),
  );
}

PlanesSuscripcion? _findPlan(
  AsyncValue<List<PlanesSuscripcion>> plansAsync,
  String? planId,
) {
  final plans = plansAsync.asData?.value;
  if (plans == null || planId == null) return null;
  try {
    return plans.firstWhere((p) => p.id == planId);
  } catch (_) {
    return null;
  }
}

final _plansProvider = FutureProvider.autoDispose<List<PlanesSuscripcion>>((ref) async {
  return ref.read(subscriptionServiceProvider).getPlans();
});

String _resolvePlanName(
  AsyncValue<List<PlanesSuscripcion>> plansAsync,
  String? storedName,
  String? planId,
) {
  if (storedName != null && storedName.isNotEmpty) return storedName;
  final plans = plansAsync.asData?.value;
  if (plans != null && planId != null) {
    final found = plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => PlanesSuscripcion(
        id: planId,
        nombre: planId,
        maxUsuarios: 0,
        maxSucursales: 0,
        almacenamientoGb: 0,
        precioMensual: 0,
      ),
    );
    return found.nombre;
  }
  if (plansAsync.isLoading) return 'Cargando plan...';
  return planId ?? 'Sin plan asignado';
}
