import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart'; // Importante para SHA-256
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_codigos_temporales.dart';

// Asumo que tienes una instancia global, si no, inyectala.
final supabase = Supabase.instance.client;

/// Servicio para gestionar códigos QR de sucursales
class QrService {
  QrService._();
  static final instance = QrService._();

  /// Genera un nuevo código QR para una sucursal.
  ///
  /// Retorna el [token] en texto plano para ser mostrado en el Widget QR una única vez.
  /// En base de datos se guarda únicamente el HASH.
  Future<String> generateQrForBranch({
    required String sucursalId,
    required String organizacionId,
    Duration? validez,
    int horasValidez = 720, // 30 días por defecto
  }) async {
    try {
      // 1. Invalida QRs anteriores para evitar múltiples activos por sucursal
      await invalidateQrForBranch(sucursalId);

      // 2. Generar token único y su hash
      final tokenRaw = _generateUniqueToken();
      final tokenHash = _hashToken(tokenRaw);

      final now = DateTime.now();
      final expiracion = now.add(validez ?? Duration(hours: horasValidez));

      // 3. Insertar en DB (Solo el hash)
      await supabase.from('qr_codigos').insert({
        'sucursal_id': sucursalId,
        'organizacion_id': organizacionId,
        'token_hash': tokenHash,
        'fecha_expiracion': expiracion.toIso8601String(),
        'es_valido': true,
        'creado_en': now.toIso8601String(),
      });

      // 4. Retornar token crudo para generar la imagen QR
      return tokenRaw;
    } catch (e) {
      throw Exception('Error generando QR: $e');
    }
  }

  /// Obtiene la metadata del QR activo.
  ///
  /// NOTA: Esto retorna el objeto con el HASH. No sirve para pintar el QR
  /// nuevamente (porque no es reversible), sirve para validar si existe uno activo
  /// o mostrar fecha de expiración en el panel administrativo.
  Future<QrCodigosTemporales?> getActiveQrMetadata(String sucursalId) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from('qr_codigos')
          .select()
          .eq('sucursal_id', sucursalId)
          .eq('es_valido', true)
          .gt('fecha_expiracion', now.toIso8601String()) // Mayor que ahora
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle(); // Usar maybeSingle es más seguro que response.isEmpty manual

      if (response == null) return null;
      return QrCodigosTemporales.fromJson(response);
    } catch (e) {
      // Manejo silencioso o log
      print('Error consultando QR activo: $e');
      return null;
    }
  }

  /// Valida un token escaneado por un empleado.
  ///
  /// Recibe el [scannedToken] (texto plano del QR), lo hashea y busca
  /// si existe, es válido y corresponde a la sucursal indicada.
  Future<bool> verifyQrToken({
    required String scannedToken,
    required String sucursalId,
  }) async {
    try {
      final hash = _hashToken(scannedToken);
      final now = DateTime.now();

      final response = await supabase
          .from('qr_codigos')
          .select('id')
          .eq('sucursal_id', sucursalId)
          .eq('token_hash', hash)
          .eq('es_valido', true)
          .gt('fecha_expiracion', now.toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Invalida todos los QR de una sucursal (Soft Delete lógico)
  Future<void> invalidateQrForBranch(String sucursalId) async {
    try {
      await supabase
          .from('qr_codigos')
          .update({'es_valido': false})
          .eq('sucursal_id', sucursalId);
    } catch (e) {
      throw Exception('Error invalidando QR: $e');
    }
  }

  /// Genera token único alfanumérico aleatorio
  String _generateUniqueToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    // Formato: XXXX-XXXX-XXXX-XXXX (16 chars + guiones)
    // Suficiente entropía para evitar colisiones en QR temporales
    String p() =>
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();

    return '${p()}-${p()}-${p()}-${p()}';
  }

  /// Hashea el token usando SHA-256
  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
