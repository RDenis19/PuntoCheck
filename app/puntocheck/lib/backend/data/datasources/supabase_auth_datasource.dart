import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación de ejemplo de autenticación usando Supabase.
///
/// Reemplaza o adapta la lógica según tu esquema de usuarios.
class SupabaseAuthDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Credenciales inválidas');
    }
    return user.id;
  }

  Future<String> signUp(String email, String password, {Map<String, dynamic>? userMetadata}) async {
    // Try to pass user metadata so the DB trigger that reads
    // `raw_user_meta_data->>'full_name'` can populate `profiles`.
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: userMetadata,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('No se pudo crear la cuenta');
    }
    return user.id;
  }

  Future<void> sendResetEmail(String email) async {
    // Supabase provee `resetPasswordForEmail`.
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String uid, String newPassword) async {
    // Para cambiar contraseña el usuario debe estar autenticado.
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> refreshSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return;
      await _client.auth.refreshSession();
    } catch (_) {
      // ignore
    }
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  void resumeSession(String uid) {
    // En Supabase la sesión se restaura automáticamente desde storage.
    // Si manejas sesiones manuales, implementa aquí.
  }

  String? findUidByEmail(String email) {
    // Puedes crear una consulta a la tabla 'users' si guardas el email ahí.
    return null;
  }
}
