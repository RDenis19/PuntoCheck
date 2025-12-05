import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  /// Sube la foto de evidencia (selfie)
  /// Retorna el `path` relativo para guardarlo en la DB.
  Future<String> uploadEvidence(File file, String userId) async {
    try {
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

      return path;
    } catch (e) {
      throw Exception('Error subiendo evidencia: $e');
    }
  }

  /// Sube certificado médico u otros documentos legales
  Future<String> uploadLegalDoc(File file, String userId) async {
    try {
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
      throw Exception('Error subiendo documento: $e');
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
}
