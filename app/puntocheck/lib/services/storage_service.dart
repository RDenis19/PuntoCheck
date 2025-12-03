import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _bucketEvidence = 'evidence';
  static const String _bucketAvatars = 'avatars';
  static const String _bucketOrgLogos = 'org_logos';

  /// Valida tamano de archivo (max 5MB).
  void _validateSize(File file) {
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    if (mb > 5.0) {
      throw Exception('El archivo excede el limite de 5MB.');
    }
  }

  Map<String, dynamic> _buildMetadata({
    String? userId,
    String? organizationId,
  }) {
    return {
      if (userId != null) 'user_id': userId,
      if (organizationId != null) 'organization_id': organizationId,
    };
  }

  /// Sube foto de perfil. Incluye metadata para cumplir RLS (user_id/org_id).
  Future<String> uploadAvatar(
    File file, {
    required String userId,
    String? organizationId,
  }) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp$fileExt';
      final metadata =
          _buildMetadata(userId: userId, organizationId: organizationId);

      await _supabase.storage.from(_bucketAvatars).upload(
            filePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              metadata: metadata,
            ),
          );

      // Guardamos path (no URL publica). Se resuelve con URL firmada al mostrar.
      return filePath;
    } catch (e) {
      throw Exception('Error subiendo avatar: $e');
    }
  }

  /// Sube evidencia de asistencia (bucket privado).
  /// Retorna el path relativo para guardar en BD.
  Future<String> uploadEvidence(File file, String userId, String orgId) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$orgId/$userId/$timestamp$fileExt';
      final metadata = _buildMetadata(userId: userId, organizationId: orgId);

      await _supabase.storage.from(_bucketEvidence).upload(
            filePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              metadata: metadata,
            ),
          );

      return filePath;
    } catch (e) {
      throw Exception('Error subiendo evidencia: $e');
    }
  }

  /// Genera URL firmada temporal para ver evidencia privada.
  Future<String> getEvidenceSignedUrl(String filePath) async {
    try {
      return await _supabase.storage
          .from(_bucketEvidence)
          .createSignedUrl(filePath, 60);
    } catch (e) {
      return 'https://placehold.co/400x300?text=No+Image';
    }
  }

  /// Convierte un path o URL en una URL firmada para `org_logos`.
  /// Tolera valores ya públicos (devuelve el mismo string).
  Future<String> resolveOrgLogoUrl(
    String urlOrPath, {
    int expiresInSeconds = 600,
  }) async {
    return _resolveSignedUrl(
      bucket: _bucketOrgLogos,
      urlOrPath: urlOrPath,
      expiresInSeconds: expiresInSeconds,
    );
  }

  /// Convierte un path o URL de avatar en URL firmada (o deja la pública).
  Future<String> resolveAvatarUrl(
    String urlOrPath, {
    int expiresInSeconds = 600,
  }) async {
    return _resolveSignedUrl(
      bucket: _bucketAvatars,
      urlOrPath: urlOrPath,
      expiresInSeconds: expiresInSeconds,
    );
  }

  String _extractPath(String urlOrPath) {
    if (!urlOrPath.startsWith('http')) {
      return urlOrPath.replaceFirst(RegExp('^/'), '');
    }
    try {
      final uri = Uri.parse(urlOrPath);
      final idx = uri.pathSegments.indexOf('object');
      if (idx != -1 && idx + 1 < uri.pathSegments.length) {
        return uri.pathSegments.sublist(idx + 1).join('/');
      }
      return uri.pathSegments.join('/');
    } catch (_) {
      return urlOrPath;
    }
  }

  Future<String> _resolveSignedUrl({
    required String bucket,
    required String urlOrPath,
    required int expiresInSeconds,
  }) async {
    if (urlOrPath.isEmpty) return urlOrPath;

    final rawPath = _extractPath(urlOrPath);
    final path =
        rawPath.startsWith('public/') ? rawPath.substring(7) : rawPath;

    try {
      return await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresInSeconds);
    } catch (_) {
      // Si falla, devolvemos lo que haya (p.e. URL pública ya accesible).
      return urlOrPath;
    }
  }

  /// Sube logo de organizacion en bucket dedicado `org_logos`.
  /// Path: orgs/{orgId}/logo_timestamp.ext
  Future<String> uploadOrganizationLogo(
    File file,
    String orgId, {
    String? userId,
  }) async {
    try {
      _validateSize(file);
      final fileExt = p.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'orgs/$orgId/logo_$timestamp$fileExt';
      final metadata = _buildMetadata(userId: userId, organizationId: orgId);

      await _supabase.storage.from(_bucketOrgLogos).upload(
            filePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              metadata: metadata,
            ),
          );

      // Guardamos path (privado) y luego resolvemos firmado al mostrar.
      return filePath;
    } catch (e) {
      throw Exception('Error subiendo logo: $e');
    }
  }
}
