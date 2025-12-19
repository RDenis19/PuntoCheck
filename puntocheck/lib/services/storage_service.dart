import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  static const _maxFileBytes = 5 * 1024 * 1024; // 5MB

  Exception _permissionHint({
    required String action,
    required String bucket,
    required Object error,
  }) {
    final msg = error.toString();
    final looksLikeRls = msg.contains('row-level security') ||
        msg.contains('policy') ||
        msg.contains('permission') ||
        msg.contains('Unauthorized') ||
        msg.contains('403');
    if (!looksLikeRls) return Exception('Error $action: $error');

    return Exception(
      'No tienes permisos para subir archivos al bucket `$bucket`. '
      'En Supabase > Storage > Policies agrega una policy para el bucket correspondiente '
      '(por ejemplo, bucket `$bucket`) permitiendo INSERT/SELECT a `authenticated` '
      'en la carpeta `auth.uid()`.'
      ' Detalle: $msg',
    );
  }

  /// Sube la foto de evidencia (selfie)
  /// Retorna una URL (signed o pública) lista para guardarla en la DB.
  ///
  /// Nota: si no se puede generar URL (por políticas de Storage), retorna el `path`
  /// relativo como fallback.
  Future<String> uploadEvidence(File file, String userId) async {
    try {
      final size = await file.length();
      if (size > _maxFileBytes) {
        throw Exception('La foto supera 5MB. Reduce calidad antes de subir.');
      }
      final fileExt = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';
      final path = '$userId/$fileName'; // Organizado por carpetas de usuario

      await supabase.storage
          .from('evidencias')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Preferimos URL firmada para que se pueda ver desde la app sin hacer público el bucket.
      try {
        // 365 días (en segundos)
        return await supabase.storage
            .from('evidencias')
            .createSignedUrl(path, 60 * 60 * 24 * 365);
      } catch (_) {
        // Si el bucket es público, usamos la URL pública; si no, devolvemos path como fallback.
        try {
          final publicUrl =
              supabase.storage.from('evidencias').getPublicUrl(path);
          if (publicUrl.isNotEmpty) return publicUrl;
        } catch (_) {}
        return path;
      }
    } catch (e) {
      throw _permissionHint(
        action: 'subiendo evidencia',
        bucket: 'evidencias',
        error: e,
      );
    }
  }

  /// Sube certificado médico u otros documentos legales
  Future<String> uploadLegalDoc(File file, String userId) async {
    try {
      final size = await file.length();
      if (size > _maxFileBytes) {
        throw Exception('El archivo supera 5MB. Adjunta uno más liviano.');
      }
      final fileExt = file.path.split('.').last;
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      await supabase.storage
          .from('documentos_legales')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return path;
    } catch (e) {
      throw _permissionHint(
        action: 'subiendo documento',
        bucket: 'documentos_legales',
        error: e,
      );
    }
  }

  /// Obtiene una URL temporal (Signed URL) para ver una imagen privada.
  /// Los buckets son privados, por lo que `getPublicUrl` NO funcionará.
  Future<String> getSignedUrl(
    String bucketId,
    String path, {
    int expiresIn = 60,
  }) async {
    try {
      final url = await supabase.storage
          .from(bucketId)
          .createSignedUrl(path, expiresIn);
      return url;
    } catch (e) {
      // Manejo de fallback o imagen placeholder
      return '';
    }
  }

  /// Sube una foto de perfil y retorna una URL firmada de larga duración.
  ///
  /// Nota: este proyecto guarda URLs (no paths) en `perfiles.foto_perfil_url`.
  Future<String> uploadProfilePhoto(File file, String userId) async {
    try {
      final size = await file.length();
      if (size > _maxFileBytes) {
        throw Exception('La imagen supera 5MB. Reduce calidad antes de subir.');
      }

      final fileExt = file.path.split('.').last;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final path = '$userId/$fileName';

      await supabase.storage.from('evidencias').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 365 días.
      return await supabase.storage
          .from('evidencias')
          .createSignedUrl(path, 60 * 60 * 24 * 365);
    } catch (e) {
      throw _permissionHint(
        action: 'subiendo foto de perfil',
        bucket: 'evidencias',
        error: e,
      );
    }
  }
}
