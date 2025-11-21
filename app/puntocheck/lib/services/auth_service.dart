import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  /// Inicia sesión con Email y Password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message); // Error legible para UI
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Recuperación de contraseña
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Obtiene el perfil completo del usuario actual desde la tabla pública
  /// Útil para recargar datos frescos (si cambió foto, rol, etc.)
  Future<Profile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      return Profile.fromJson(data);
    } catch (e) {
      // Si el trigger falló o el usuario no existe en profiles aún
      return null;
    }
  }

  /// Actualiza datos del perfil (Avatar, Teléfono)
  Future<void> updateProfile(Profile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson()) // Solo envía campos editables definidos en toJson
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }
}