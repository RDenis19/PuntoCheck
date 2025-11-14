import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicializa Supabase. Por defecto intenta leer las variables de entorno
/// de compilación `SUPABASE_URL` y `SUPABASE_ANON_KEY` (via --dart-define).
class SupabaseBootstrap {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _envKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    final url = supabaseUrl ?? _envUrl;
    final key = supabaseAnonKey ?? _envKey;
    if (url.isEmpty || key.isEmpty) {
      throw Exception('Supabase URL y ANON KEY no proporcionados. Usa --dart-define o pasa las variables.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
  }
}
