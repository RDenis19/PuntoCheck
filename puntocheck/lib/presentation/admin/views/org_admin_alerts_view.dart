import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/models/alertas_cumplimiento.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/providers/org_admin_providers.dart';
import 'package:puntocheck/providers/auth_providers.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/presentation/admin/widgets/alert_detail_dialog.dart';
import 'package:puntocheck/presentation/admin/widgets/notification_card.dart';
import 'package:puntocheck/presentation/admin/widgets/audit_log_card.dart';

/// Vista principal de alertas, notificaciones y auditoría
class OrgAdminAlertsView extends ConsumerStatefulWidget {
  const OrgAdminAlertsView({super.key});

  @override
  ConsumerState<OrgAdminAlertsView> createState() => _OrgAdminAlertsViewState();
}

class _OrgAdminAlertsViewState extends ConsumerState<OrgAdminAlertsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canViewAudit {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return false;
    return profile.rol == RolUsuario.superAdmin || 
           profile.rol == RolUsuario.auditor;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas y Auditoría'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.neutral600,
          indicatorColor: AppColors.primaryRed,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            const Tab(icon: Icon(Icons.shield_outlined), text: 'Alertas'),
            Tab(
              icon: Badge(
                isLabelVisible: unreadCount.valueOrNull != null &&
                    unreadCount.value! > 0,
                label: Text('${unreadCount.value ?? 0}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              text: 'Notificaciones',
            ),
            if (_canViewAudit)
              const Tab(icon: Icon(Icons.history), text: 'Auditoría'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertasTab(),
          _NotificationsTab(),
          if (_canViewAudit) _AuditTab(),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1: ALERTAS
// ============================================================================
class _AlertasTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(orgAdminAlertsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgAdminAlertsProvider);
      },
      child: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Error cargando alertas: $e'),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const _EmptyState(
              icon: Icons.shield_outlined,
              text: 'Sin alertas pendientes',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
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

  Color get _severityColor {
    switch (alert.gravedad?.value ?? 'moderada') {
      case 'grave_legal':
        return AppColors.errorRed;
      case 'moderada':
        return AppColors.warningOrange;
      default:
        return AppColors.infoBlue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _severityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.shield_outlined, color: _severityColor, size: 28),
        title: Text(
          alert.tipoIncumplimiento,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          alert.detalleTecnico?['descripcion'] ?? 'Sin descripción',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            alert.gravedad?.value ?? 'Media',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _severityColor,
            ),
          ),
        ),
        onTap: () => _showAlertDetail(context, ref),
      ),
    );
  }

  Future<void> _showAlertDetail(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(alertsControllerProvider.notifier);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDetailDialog(
        alert: alert,
        onResolve: (status, justification) => controller.resolve(
          alertId: alert.id,
          newStatus: status,
          justification: justification,
        ),
      ),
    );

    if (result ==  true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerta resuelta exitosamente'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}

// ============================================================================
// TAB 2: NOTIFICACIONES
// ============================================================================
class _NotificationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(orgAdminNotificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgAdminNotificationsProvider);
      },
      child: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Error cargando notificaciones: $e'),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyState(
              icon: Icons.notifications_outlined,
              text: 'Sin notificaciones',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _markAsRead(ref, notification.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAsRead(WidgetRef ref, String notificationId) async {
    try {
      await ref
          .read(alertsControllerProvider.notifier)
          .markNotificationRead(notificationId);
    } catch (e) {
      // Error silencioso
    }
  }
}

// ============================================================================
// TAB 3: AUDITORÍA
// ============================================================================
class _AuditTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(orgAdminAuditLogProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgAdminAuditLogProvider);
      },
      child: auditAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Error cargando auditoría: $e'),
        data: (logs) {
          if (logs.isEmpty) {
            return const _EmptyState(
              icon: Icons.history,
              text: 'Sin logs de auditoría',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return AuditLogCard(log: logs[index]);
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================
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
          Icon(icon, size: 64, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
