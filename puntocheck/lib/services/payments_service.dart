import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/pagos_suscripciones.dart';
import 'supabase_client.dart';

class PaymentsService {
  PaymentsService._();
  static final instance = PaymentsService._();

  // ---------------------------------------------------------------------------
  // CREAR PAGO (Org Admin)
  // ---------------------------------------------------------------------------
  Future<PagosSuscripciones> createPayment({
    required String orgId,
    required String planId,
    required double monto,
    required String comprobanteUrl,
    String? referencia,
  }) async {
    try {
      final response = await supabase
          .from('pagos_suscripciones')
          .insert({
            'organizacion_id': orgId,
            'plan_id': planId,
            'monto': monto,
            'comprobante_url': comprobanteUrl,
            'referencia_bancaria': referencia,
            // estado queda 'pendiente' por default en DB
          })
          .select()
          .single();

      return PagosSuscripciones.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(_friendlyError(e));
    } catch (e) {
      throw Exception('Error creando pago: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LISTAR PAGOS (Org Admin: solo su org, Super Admin: global)
  // ---------------------------------------------------------------------------
  Future<List<PagosSuscripciones>> listPayments({
    String? orgId,
    EstadoPago? estado,
  }) async {
    try {
      var query = supabase.from('pagos_suscripciones').select();

      if (orgId != null) {
        query = query.eq('organizacion_id', orgId);
      }
      if (estado != null) {
        query = query.eq('estado', estado.value);
      }

      final response = await query.order('creado_en', ascending: false);

      return (response as List)
          .map((e) => PagosSuscripciones.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_friendlyError(e));
    } catch (e) {
      throw Exception('Error obteniendo pagos: $e');
    }
  }

  Future<List<PagosSuscripciones>> listPendingPayments() {
    return listPayments(estado: EstadoPago.pendiente);
  }

  // ---------------------------------------------------------------------------
  // VALIDAR PAGO (Super Admin)
  // ---------------------------------------------------------------------------
  Future<void> updatePaymentStatus({
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
    } on PostgrestException catch (e) {
      throw Exception(_friendlyError(e));
    } catch (e) {
      throw Exception('Error actualizando pago: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _friendlyError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (e.code == '42501' || msg.contains('row-level security')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    if (msg.contains('violates unique constraint')) {
      return 'Registro duplicado.';
    }
    return e.message;
  }
}
