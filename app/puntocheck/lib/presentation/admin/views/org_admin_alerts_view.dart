import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class OrgAdminAlertsView extends ConsumerWidget {
  const OrgAdminAlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(orgAdminAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas y notificaciones')),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState(
              icon: Icons.shield_outlined,
              text: 'Sin alertas pendientes',
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alert = list[index];
              return _AlertTile(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final AlertasCumplimiento alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severity = alert.gravedad?.value ?? 'moderada';
    Color badge;
    switch (severity) {
      case 'grave_legal':
        badge = AppColors.errorRed;
        break;
      case 'moderada':
      case 'media':
        badge = AppColors.warningOrange;
        break;
      default:
        badge = AppColors.infoBlue;
    }

    return ListTile(
      leading: Icon(Icons.shield_moon_outlined, color: badge),
      title: Text(
        alert.tipoIncumplimiento,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(alert.detalleTecnico?['descripcion'] ?? 'Detalle no disponible'),
      trailing: TextButton(
        onPressed: () async {
          await _justify(context, ref);
        },
        child: const Text('Justificar'),
      ),
    );
  }

  Future<void> _justify(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Justificar alerta'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Justificación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != true) return;
    try {
      await ref
          .read(complianceServiceProvider)
          .justifyAlert(alert.id, ctrl.text.trim());
      ref.invalidate(orgAdminAlertsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerta justificada')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
