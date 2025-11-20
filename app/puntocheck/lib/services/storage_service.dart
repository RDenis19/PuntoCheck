import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageDatasource {
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucket = 'avatars';

  Future<String?> uploadProfilePhoto(String uid, {String? localPath}) async {
    if (localPath == null) return null;
    final file = File(localPath);
    if (!file.existsSync()) return null;

    final path =
        'profiles/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

    // Subida de archivo en Supabase v2 (lanza excepción si falla)
    await _client.storage.from(_bucket).upload(path, file);

    // Obtener URL pública
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);

    return publicUrl;
  }
}
