import 'dart:math';
import '../models/qr_codigos_temporales.dart';
import 'supabase_client.dart';

/// Servicio para gestionar códigos QR de sucursales
class QrService {
  QrService._();
  static final instance = QrService._();

  /// Genera un código QR para una sucursal
  /// Retorna el token que debe ser codificado en el QR
  Future<String> generateQrForBranch({
    required String sucursalId,
    required String organizacionId,
    int horasValidez = 720, // 30 días por defecto
  }) async {
    try {
      // Generar token único
      final token = _generateUniqueToken();
      final tokenHash = _hashToken(token);
      final now = DateTime.now();
      final expiracion = now.add(Duration(hours: horasValidez));

      // Insertar en DB
      await supabase.from('qr_codigos').insert({
        'sucursal_id': sucursalId,
        'organizacion_id': organizacionId,
        'token_hash': tokenHash,
        'fecha_expiracion': expiracion.toIso8601String(),
        'es_valido': true,
      });

      // Retornar token (no el hash)
      return token;
    } catch (e) {
      throw Exception('Error generando QR: $e');
    }
  }

  /// Obtiene el QR activo de una sucursal
  Future<QrCodigosTemporales?> getActiveQrForBranch(
    String sucursalId,
  ) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('qr_codigos')
          .select()
          .eq('sucursal_id', sucursalId)
          .eq('es_valido', true)
          .gte('fecha_expiracion', now.toIso8601String())
          .order('creado_en', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return QrCodigosTemporales.fromJson(response.first);
    } catch (e) {
      throw Exception('Error obteniendo QR: $e');
    }
  }

  /// Invalida todos los QR de una sucursal
  Future<void> invalidateQrForBranch(String sucursalId) async {
    try {
      await supabase
          .from('qr_codigos')
          .update({'es_valido': false}).eq('sucursal_id', sucursalId);
    } catch (e) {
      throw Exception('Error invalidando QR: $e');
    }
  }

  /// Genera token único alfanumérico
  String _generateUniqueToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    
    // Formato: ORGID-BRANCHID-RANDOM (ej: A1B2-C3D4-E5F6)
    final part1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final part3 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    
    return '$part1-$part2-$part3';
  }

  /// Hashea el token (simple, puede mejorarse con crypto)
  String _hashToken(String token) {
    // Por ahora, solo almacenamos el token directamente
    // En producción, usar package:crypto para hash real
    return token;
  }
}
