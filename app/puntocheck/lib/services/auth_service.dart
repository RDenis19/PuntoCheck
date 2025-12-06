import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfiles.dart';
import '../models/organizaciones.dart';
import 'supabase_client.dart';

class AuthService {
  // Singleton
  AuthService._();
  static final instance = AuthService._();

  /// Obtener usuario actual de Auth (Email/ID)
  User? get currentUser => supabase.auth.currentUser;

  /// Stream para escuchar cambios de sesión (Login/Logout)
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Iniciar sesión
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message); // "Credenciales inválidas", etc.
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Obtener el perfil completo del usuario logueado
  /// Hace un JOIN con la tabla de Organizaciones para tener todo el contexto.
  Future<Map<String, dynamic>> getFullUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('No hay usuario logueado');

    try {
      final response = await supabase
          .from('perfiles')
          .select('*, organizaciones(*)') // Join con organizaciones
          .eq('id', userId)
          .single();

      // Mapeamos manualmente para separar Perfil y Organización
      final perfil = Perfiles.fromJson(response);

      Organizaciones? org;
      if (response['organizaciones'] != null) {
        org = Organizaciones.fromJson(response['organizaciones']);
      }

      return {'perfil': perfil, 'organizacion': org};
    } on PostgrestException catch (e) {
      throw Exception('Error cargando perfil: ${e.message}');
    }
  }

  /// Crear usuario en Auth (email/password) con metadata opcional.
  /// Útil para que el Super Admin genere admins de organización en un solo paso
  /// y que el trigger `handle_new_user` cree la fila en `perfiles`.
  Future<User> createUser({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('No se obtuvo usuario al crear la cuenta');
      }
      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error creando usuario: $e');
    }
  }
}
