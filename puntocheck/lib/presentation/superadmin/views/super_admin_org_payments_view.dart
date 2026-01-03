import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/models/pagos_suscripciones.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/shared/widgets/empty_state.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

Color _statusColor(EstadoPago estado) {
  switch (estado) {
    case EstadoPago.aprobado:
      return AppColors.successGreen;
    case EstadoPago.rechazado:
      return AppColors.errorRed;
    case EstadoPago.pendiente:
      return AppColors.warningOrange;
  }
}

class SuperAdminOrgPaymentsView extends ConsumerWidget {
  final String orgId;

  const SuperAdminOrgPaymentsView({super.key, required this.orgId});

  void _showDetails({
    required BuildContext context,
    required WidgetRef ref,
    required PagosSuscripciones pago,
    required Map<String, String> planNames,
    required RolUsuario? role,
    required bool isProcessing,
  }) {
    final status = pago.estado ?? EstadoPago.pendiente;
    final statusColor = _statusColor(status);
    final statusLabel = status.value.toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 12,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.16),
                        AppColors.primaryRed.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planNames[pago.planId] ?? 'Plan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${pago.monto.toStringAsFixed(2)} · Ref: ${pago.referenciaBancaria ?? 'N/D'}',
                        style: const TextStyle(color: AppColors.neutral700),
                      ),
                    ],
                  ),
                ),
                _StatusChip(color: statusColor, label: statusLabel),
              ],
            ),
            const SizedBox(height: 14),
            _DetailRow(
              label: 'Estado',
              value: statusLabel,
              color: statusColor,
              icon: Icons.verified_outlined,
            ),
            _DetailRow(
              label: 'Registrado',
              value: pago.creadoEn != null
                  ? pago.creadoEn!.toLocal().toString().split(' ').first
                  : 'No registrada',
              icon: Icons.event,
            ),
            _DetailRow(
              label: 'Validado',
              value: pago.fechaValidacion != null
                  ? pago.fechaValidacion!.toLocal().toString().split(' ').first
                  : 'En revisión',
              icon: Icons.verified_user_outlined,
            ),
            _DetailRow(
              label: 'Comprobante',
              value: pago.comprobanteUrl,
              icon: Icons.link_outlined,
            ),
            _DetailRow(
              label: 'Observaciones',
              value: (pago.observaciones ?? '').isEmpty
                  ? 'Sin observaciones'
                  : pago.observaciones!,
              icon: Icons.note_alt_outlined,
            ),
            const SizedBox(height: 14),
            if (role == RolUsuario.superAdmin && status == EstadoPago.pendiente)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              await ref
                                  .read(
                                    paymentValidationControllerProvider
                                        .notifier,
                                  )
                                  .reject(pago.id);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.primaryRed,
                      ),
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
                                    paymentValidationControllerProvider
                                        .notifier,
                                  )
                                  .approve(pago.id);
                              if (context.mounted) Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role != RolUsuario.superAdmin && role != RolUsuario.orgAdmin) {
      return const Scaffold(
        body: Center(child: Text('No tienes acceso a pagos.')),
      );
    }
    final orgAsync = ref.watch(organizationDetailProvider(orgId));
    final paymentsAsync = ref.watch(organizationPaymentsProvider(orgId));
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final validationState = ref.watch(paymentValidationControllerProvider);

    final planNames = <String, String>{};
    plansAsync.whenData((plans) {
      for (final plan in plans) {
        planNames[plan.id] = plan.nombre;
      }
    });

    Future<void> onRefresh() async {
      ref
        ..invalidate(organizationPaymentsProvider(orgId))
        ..invalidate(pendingPaymentsProvider);
      await ref.read(organizationPaymentsProvider(orgId).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: orgAsync.maybeWhen(
          data: (org) => Text('Pagos: ${org.razonSocial}'),
          orElse: () => const Text('Pagos y suscripciones'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              'Revisar y validar pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Historial de comprobantes enviados por la organizacion.',
              style: TextStyle(color: AppColors.neutral700),
            ),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const EmptyState(
                    title: 'Sin pagos registrados',
                    message:
                        'Cuando la organizacion suba un comprobante aparecera aqui.',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return Column(
                  children: [
                    for (final pago in payments) ...[
                      _PaymentCard(
                        pago: pago,
                        planName: planNames[pago.planId],
                        isProcessing: validationState.isLoading,
                        onTap: () => _showDetails(
                          context: context,
                          ref: ref,
                          pago: pago,
                          planNames: planNames,
                          role: role,
                          isProcessing: validationState.isLoading,
                        ),
                        onApprove:
                            role == RolUsuario.superAdmin &&
                                pago.estado == EstadoPago.pendiente
                            ? () async {
                                await ref
                                    .read(
                                      paymentValidationControllerProvider
                                          .notifier,
                                    )
                                    .approve(pago.id);
                                ref.invalidate(
                                  organizationPaymentsProvider(orgId),
                                );
                              }
                            : null,
                        onReject:
                            role == RolUsuario.superAdmin &&
                                pago.estado == EstadoPago.pendiente
                            ? () async {
                                await ref
                                    .read(
                                      paymentValidationControllerProvider
                                          .notifier,
                                    )
                                    .reject(pago.id);
                                ref.invalidate(
                                  organizationPaymentsProvider(orgId),
                                );
                              }
                            : null,
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
                'No se pudieron cargar pagos: $error',
                style: const TextStyle(color: AppColors.errorRed),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.pago,
    required this.planName,
    required this.isProcessing,
    required this.onTap,
    this.onApprove,
    this.onReject,
  });

  final PagosSuscripciones pago;
  final String? planName;
  final bool isProcessing;
  final VoidCallback onTap;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  @override
  Widget build(BuildContext context) {
    final status = pago.estado ?? EstadoPago.pendiente;
    final statusColor = _statusColor(status);
    final statusLabel = status.value.toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryRed.withValues(alpha: 0.14),
                    AppColors.primaryRed.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.receipt_long_rounded, color: AppColors.primaryRed),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName ?? 'Plan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.neutral900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${pago.monto.toStringAsFixed(2)} · Ref: ${pago.referenciaBancaria ?? 'N/D'}',
                    style: const TextStyle(color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(color: statusColor, label: statusLabel),
                      if (pago.creadoEn != null)
                        Text(
                          'Fecha: ${pago.creadoEn!.toLocal().toString().split(' ').first}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (status == EstadoPago.pendiente && onApprove != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Aprobar',
                    onPressed: isProcessing ? null : onApprove,
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                  ),
                  IconButton(
                    tooltip: 'Rechazar',
                    onPressed: isProcessing ? null : onReject,
                    icon: const Icon(Icons.close_rounded, color: AppColors.primaryRed),
                  ),
                ],
              )
            else
              _StatusChip(color: statusColor, label: statusLabel),
          ],
        ),
      ),
    );
  }

  Color _statusColor(EstadoPago estado) {
    switch (estado) {
      case EstadoPago.aprobado:
        return AppColors.successGreen;
      case EstadoPago.rechazado:
        return AppColors.errorRed;
      case EstadoPago.pendiente:
        return AppColors.warningOrange;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.neutral900;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
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
