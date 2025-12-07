import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos y suscripciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : () => _showCreateDialog(context, orgAsync),
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState(
              icon: Icons.receipt_long_outlined,
              text: 'Sin pagos registrados.',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pago = list[index];
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Pago ${pago.id}'),
                subtitle: Text(
                  'Monto: ${pago.monto.toStringAsFixed(2)} | Estado: ${pago.estado?.value ?? 'pendiente'}',
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado en estado pendiente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.neutral500),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }
}
