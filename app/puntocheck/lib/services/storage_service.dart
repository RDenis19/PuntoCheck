import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart'
    as p; // Necesario para obtener extensión del archivo

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  // Nombres de los buckets definidos en el SQL
  static const String _bucketEvidencias = 'evidencias';
  static const String _bucketDocumentos = 'documentos_legales';

  /// Sube una foto de evidencia (Selfie de asistencia).
  /// Retorna el `path` relativo dentro del bucket para guardarlo en la BD.
  ///
  /// [file]: Archivo de imagen comprimido.
  /// [userId]: ID del usuario para organizar carpetas (user_id/timestamp.jpg).
  Future<String> uploadEvidencia(File file, String userId) async {
    // Generar nombre único: user_id/timestamp.jpg
    final extension = p.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId/$timestamp$extension';

    try {
      await _supabase.storage
          .from(_bucketEvidencias)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // En Supabase DB, guardamos el path relativo o la URL pública.
      // Dado que el bucket es privado (según SQL), necesitamos el path
      // para luego generar Signed URLs al mostrarlo.
      return fileName;
    } on StorageException catch (e) {
      throw Exception('Error al subir evidencia: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado en subida: $e');
    }
  }

  /// Sube documento de soporte para permisos (PDF/IMG).
  Future<String> uploadDocumentoLegal(File file, String userId) async {
    final extension = p.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Estructura: user_id/docs/timestamp.pdf
    final fileName = '$userId/docs/$timestamp$extension';

    try {
      await _supabase.storage
          .from(_bucketDocumentos)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: false),
          );
      return fileName;
    } on StorageException catch (e) {
      throw Exception('Error al subir documento: ${e.message}');
    }
  }

  /// Obtiene una URL temporal (Signed URL) para ver una imagen privada.
  /// Los buckets fueron configurados como PRIVADOS, así que esto es obligatorio.
  Future<String> getSignedUrl(String path, {bool isDocumento = false}) async {
    final bucket = isDocumento ? _bucketDocumentos : _bucketEvidencias;

    try {
      // La URL será válida por 60 segundos (seguridad)
      final url = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, 60);
      return url;
    } catch (e) {
      // Si falla (ej: archivo borrado), retornar string vacío o placeholder
      return '';
    }
  }
}
