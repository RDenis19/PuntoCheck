import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/organizaciones.dart';
import '../models/super_admin_dashboard.dart';
import 'subscription_service.dart';
import 'supabase_client.dart';

class SuperAdminService {
  SuperAdminService._();
  static final instance = SuperAdminService._();

  /// Carga el panel del Super Admin con datos de planes, pagos y organizaciones.
  Future<SuperAdminDashboardData> loadDashboard() async {
    try {
      final List<dynamic> organizationsResponse = await supabase
          .from('organizaciones')
          .select()
          .eq('eliminado', false)
          .order('creado_en', ascending: false);

      final plans = await SubscriptionService.instance.getPlans();
      final pendingPayments =
          await SubscriptionService.instance.getPendingPayments();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final List<dynamic> revenueRows = await supabase
          .from('pagos_suscripciones')
          .select()
          .eq('estado', EstadoPago.aprobado.value)
          .gte('fecha_pago', startOfMonth);

      final organizations = organizationsResponse
          .map((e) => Organizaciones.fromJson(e as Map<String, dynamic>))
          .toList();

      final recentOrganizations = organizations.take(3).toList();

      final activeOrganizations = organizations
          .where((org) => org.estadoSuscripcion == EstadoSuscripcion.activo)
          .length;
      final trialOrganizations = organizations
          .where((org) => org.estadoSuscripcion == EstadoSuscripcion.prueba)
          .length;

      final monthlyRevenue = revenueRows.fold<double>(0, (sum, row) {
        final monto = row['monto'];
        if (monto == null) return sum;
        return sum + (monto as num).toDouble();
      });

      return SuperAdminDashboardData(
        organizations: organizations,
        recentOrganizations: recentOrganizations,
        plans: plans,
        pendingPayments: pendingPayments,
        monthlyRevenue: monthlyRevenue,
        totalOrganizations: organizations.length,
        activeOrganizations: activeOrganizations,
        trialOrganizations: trialOrganizations,
      );
    } on PostgrestException catch (e) {
      throw Exception('Error cargando dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Error cargando dashboard: $e');
    }
  }
}
