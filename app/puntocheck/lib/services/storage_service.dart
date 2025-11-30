import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Nombres exactos de los buckets
  static const String _bucketEvidence = 'evidence'; // Privado
  static const String _bucketAvatars = 'avatars';   // Público

  /// Valida tamaño de archivo (Max 5MB)
  void _validateSize(File file) {
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    if (mb > 5.0) {
      throw Exception('El archivo excede el límite de 5MB.');
    }
  }

  /// Sube FOTO DE PERFIL (Público)
  Future<String> uploadAvatar(File file, String userId) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      // Guardamos como: user_id/avatar.jpg (sobrescribir)
      // Usamos timestamp para evitar problemas de caché en la UI si el nombre es siempre igual
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp$fileExt';

      await _supabase.storage.from(_bucketAvatars).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600', 
              upsert: true
            ),
          );

      return _supabase.storage.from(_bucketAvatars).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Error subiendo avatar: $e');
    }
  }

  /// Sube EVIDENCIA DE ASISTENCIA (Privado)
  /// Retorna: Path relativo para guardar en BD
  Future<String> uploadEvidence(File file, String userId, String orgId) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Estructura: org_id/user_id/timestamp.jpg
      final filePath = '$orgId/$userId/$timestamp$fileExt';

      await _supabase.storage.from(_bucketEvidence).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600', 
              upsert: false 
            ),
          );

      return filePath;
    } catch (e) {
      throw Exception('Error subiendo evidencia: $e');
    }
  }

  /// Genera URL firmada temporal para ver evidencia privada
  Future<String> getEvidenceSignedUrl(String filePath) async {
    try {
      // Validez de 60 segundos es suficiente para renderizar la imagen
      return await _supabase.storage
          .from(_bucketEvidence)
          .createSignedUrl(filePath, 60);
    } catch (e) {
      // Fallback visual si la imagen fue borrada o hay error
      return 'https://placehold.co/400x300?text=No+Image';
    }
  }

  /// Sube LOGO de organizacion en bucket publico (reutiliza bucket avatars).
  /// Path: orgs/{orgId}/logo_timestamp.ext
  Future<String> uploadOrganizationLogo(File file, String orgId) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'orgs/$orgId/logo_$timestamp$fileExt';

      await _supabase.storage.from(_bucketAvatars).upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      return _supabase.storage.from(_bucketAvatars).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Error subiendo logo: $e');
    }
  }
}
