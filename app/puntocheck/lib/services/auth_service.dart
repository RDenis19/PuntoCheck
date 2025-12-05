import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/models/perfil_model.dart';
import 'package:puntocheck/models/enums.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  // --- GETTERS DE SESIÓN ---

  User? get currentUser => _supabase.auth.currentUser;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  bool get isSessionValid => _supabase.auth.currentSession != null;

  // Stream para escuchar cambios de auth en tiempo real (Login/Logout)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- ACCIONES DE AUTENTICACIÓN ---

  /// Inicia sesión con email y contraseña
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      // Tip: Mapear errores de Supabase a mensajes amigables
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Recuperación de contraseña (envía email)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- GESTIÓN DE PERFIL (CRÍTICO) ---

  /// Obtiene el perfil completo del usuario actual desde la tabla 'perfiles'.
  /// Se usa inmediatamente después del login para saber el Rol y Org.
  Future<PerfilModel?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // maybeSingle devuelve null si no existe, en vez de error

      if (data == null) return null;

      return PerfilModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al cargar perfil: ${e.message}');
    }
  }

  /// Actualiza datos permitidos del perfil (Teléfono, Foto)
  /// Nota: El RLS solo permite al usuario editar su propio perfil.
  Future<void> updateMyProfile({String? telefono, String? fotoUrl}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No hay sesión activa');

    try {
      await _supabase
          .from('perfiles')
          .update({
            if (telefono != null) 'telefono': telefono,
            if (fotoUrl != null) 'foto_perfil_url': fotoUrl,
            // 'updated_at' se maneja con trigger en DB
          })
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error actualizando perfil: ${e.message}');
    }
  }

  // --- UTILS ---

  String _handleAuthError(AuthException e) {
    if (e.message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (e.message.contains('Email not confirmed')) {
      return 'Por favor confirma tu correo electrónico.';
    }
    return e.message; // Retornar mensaje original por defecto
  }
}
