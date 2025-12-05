import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitudes_permisos.dart';
import '../models/alertas_cumplimiento.dart';
import '../models/enums.dart'; // Para acceder a TipoPermiso.value
import 'supabase_client.dart';

class ComplianceService {
  ComplianceService._();
  static final instance = ComplianceService._();

  /// Crear una solicitud de permiso
  Future<void> requestPermission({
    required String orgId,
    required TipoPermiso tipo,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
    String? docPath, // Path de storage si subió certificado
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    try {
      await supabase.from('solicitudes_permisos').insert({
        'organizacion_id': orgId,
        'solicitante_id': user.id,
        'tipo':
            tipo.value, // Usamos .value para obtener el string exacto del Enum
        'fecha_inicio': startDate.toIso8601String(),
        'fecha_fin': endDate.toIso8601String(),
        'dias_totales': totalDays,
        'motivo_detalle': reason,
        'documento_soporte_url': docPath,
        // Estado por defecto es 'pendiente' en DB
      });
    } on PostgrestException catch (e) {
      throw Exception('Error solicitando permiso: ${e.message}');
    }
  }

  /// Ver mis solicitudes
  Future<List<SolicitudesPermisos>> getMyRequests() async {
    try {
      final response = await supabase
          .from('solicitudes_permisos')
          .select()
          .eq('solicitante_id', supabase.auth.currentUser!.id)
          .order('creado_en', ascending: false);

      return (response as List)
          .map((json) => SolicitudesPermisos.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error cargando solicitudes: $e');
    }
  }

  /// (Solo Managers/Admin) Ver alertas de cumplimiento de mi organización
  Future<List<AlertasCumplimiento>> getOrgAlerts(String orgId) async {
    try {
      final response = await supabase
          .from('alertas_cumplimiento')
          .select()
          .eq('organizacion_id', orgId)
          .eq('estado', 'pendiente') // Solo las no resueltas
          .order('fecha_deteccion', ascending: false);

      return (response as List)
          .map((json) => AlertasCumplimiento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error cargando alertas: $e');
    }
  }
}
