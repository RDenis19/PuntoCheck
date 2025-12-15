import 'package:puntocheck/models/banco_horas_compensatorias.dart';
import 'package:puntocheck/services/supabase_client.dart';

/// Servicio para gestión de banco de horas compensatorias
class HoursBankService {
  // Sin variable de instancia, usar supabase directamente

  static final HoursBankService _instance = HoursBankService._internal();
  factory HoursBankService() => _instance;
  HoursBankService._internal();

  static HoursBankService get instance => _instance;

  /// Obtiene registros del banco de horas de una organización
  Future<List<BancoHorasCompensatorias>> getHoursBankRecords(
    String organizacionId, {
    String? empleadoId,
  }) async {
    try {
      var query = supabase
          .from('banco_horas')
          .select()
          .eq('organizacion_id', organizacionId);

      if (empleadoId != null) {
        query = query.eq('empleado_id', empleadoId);
      }

      final response = await query.order('creado_en', ascending: false);
      return (response as List)
          .map((e) => BancoHorasCompensatorias.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener banco de horas: $e');
    }
  }

  /// Crea un nuevo registro de horas
  Future<BancoHorasCompensatorias> createHoursEntry({
    required String organizacionId,
    required String empleadoId,
    required double cantidadHoras,
    required String concepto,
    bool aceptaRenunciaPago = false,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await supabase
          .from('banco_horas')
          .insert({
            'organizacion_id': organizacionId,
            'empleado_id': empleadoId,
            'cantidad_horas': cantidadHoras,
            'concepto': concepto,
            'acepta_renuncia_pago': aceptaRenunciaPago,
            'aprobado_por_id': userId,
          })
          .select()
          .single();

      return BancoHorasCompensatorias.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear registro de horas: $e');
    }
  }

  /// Obtiene estadísticas de horas por empleado
  Future<Map<String, double>> getEmployeeStats(
    String organizacionId,
    String empleadoId,
  ) async {
    try {
      final records = await getHoursBankRecords(
        organizacionId,
        empleadoId: empleadoId,
      );

      double totalAcumulado = 0;

      for (final record in records) {
        totalAcumulado += record.cantidadHoras;
      }

      return {
        'acumulado': totalAcumulado,
        'registros': records.length.toDouble(),
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas: $e');
    }
  }
}
