import 'organizaciones.dart';
import 'pagos_suscripciones.dart';
import 'planes_suscripcion.dart';

class SuperAdminDashboardData {
  final List<Organizaciones> organizations;
  final List<Organizaciones> recentOrganizations;
  final List<PlanesSuscripcion> plans;
  final List<PagosSuscripciones> pendingPayments;
  final double monthlyRevenue;
  final int totalOrganizations;
  final int activeOrganizations;
  final int trialOrganizations;

  const SuperAdminDashboardData({
    required this.organizations,
    required this.recentOrganizations,
    required this.plans,
    required this.pendingPayments,
    required this.monthlyRevenue,
    required this.totalOrganizations,
    required this.activeOrganizations,
    required this.trialOrganizations,
  });

  int get pendingPaymentsCount => pendingPayments.length;

  int get inactiveOrganizations =>
      totalOrganizations - activeOrganizations - trialOrganizations;
}
