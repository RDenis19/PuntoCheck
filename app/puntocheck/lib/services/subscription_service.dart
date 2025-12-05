import '../models/planes_suscripcion.dart';
import '../models/pagos_suscripciones.dart';
import '../models/enums.dart';
import 'supabase_client.dart';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  // ---------------------------------------------------------------------------
  // GESTIÓN DE PLANES (Super Admin: Write / Org Admin: Read)
  // ---------------------------------------------------------------------------

  /// Obtener todos los planes disponibles
  Future<List<PlanesSuscripcion>> getPlans() async {
    try {
      final response = await supabase
          .from('planes_suscripcion')
          .select()
          .order('precio_mensual', ascending: true);
      return (response as List)
          .map((e) => PlanesSuscripcion.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener planes: $e');
    }
  }

  /// Crear nuevo plan (Solo Super Admin - RLS proteje esto)
  Future<void> createPlan(PlanesSuscripcion plan) async {
    try {
      // .toJson() debe excluir 'id' y 'creado_en' si son generados por DB
      final data = plan.toJson();
      data.remove('id');
      data.remove('creado_en');

      await supabase.from('planes_suscripcion').insert(data);
    } catch (e) {
      throw Exception('Error creando plan: $e');
    }
  }

  /// Modificar plan existente (Solo Super Admin)
  Future<void> updatePlan(String id, Map<String, dynamic> updates) async {
    try {
      await supabase.from('planes_suscripcion').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error actualizando plan: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE PAGOS Y FACTURACIÓN
  // ---------------------------------------------------------------------------

  /// Subir comprobante (Org Admin)
  Future<void> uploadPayment({
    required String orgId,
    required String planId,
    required double monto,
    required String comprobanteUrl,
    String? referencia,
  }) async {
    try {
      await supabase.from('pagos_suscripciones').insert({
        'organizacion_id': orgId,
        'plan_id': planId,
        'monto': monto,
        'comprobante_url': comprobanteUrl,
        'referencia_bancaria': referencia,
        'estado': EstadoPago.pendiente.value,
      });
    } catch (e) {
      throw Exception('Error subiendo pago: $e');
    }
  }

  /// Obtener pagos pendientes de validación (Solo Super Admin)
  Future<List<PagosSuscripciones>> getPendingPayments() async {
    try {
      final response = await supabase
          .from('pagos_suscripciones')
          .select()
          .eq('estado', EstadoPago.pendiente.value)
          .order('fecha_pago', ascending: false);
      return (response as List)
          .map((e) => PagosSuscripciones.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo pagos pendientes: $e');
    }
  }

  /// Validar Pago (Aprobar/Rechazar) (Solo Super Admin)
  Future<void> validatePayment({
    required String pagoId,
    required EstadoPago nuevoEstado,
    String? observaciones,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase
          .from('pagos_suscripciones')
          .update({
            'estado': nuevoEstado.value,
            'validado_por_id': userId,
            'fecha_validacion': DateTime.now().toIso8601String(),
            'observaciones': observaciones,
          })
          .eq('id', pagoId);

      // Nota: Si se aprueba, un Trigger en PostgreSQL debería actualizar
      // el estado de la organización a 'activo'.
    } catch (e) {
      throw Exception('Error validando pago: $e');
    }
  }
}
