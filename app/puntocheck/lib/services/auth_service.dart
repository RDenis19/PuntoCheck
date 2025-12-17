import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organizaciones.dart';
import '../models/perfiles.dart';
import 'supabase_client.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    try {
      await _withTransientNetworkRetry(
        () => supabase.auth.signInWithPassword(email: email, password: password),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      final msg = _friendlyNetworkMessage(e);
      throw Exception(msg ?? 'Error inesperado al iniciar sesión: $e');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _withTransientNetworkRetry(
        () => supabase.auth.updateUser(UserAttributes(password: newPassword)),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      final msg = _friendlyNetworkMessage(e);
      throw Exception(msg ?? 'Error actualizando contraseña: $e');
    }
  }

  Future<Map<String, dynamic>> getFullUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('No hay usuario logueado');

    try {
      final response = await _withTransientNetworkRetry(
        () => supabase
            .from('perfiles')
            .select('*, organizaciones(*)')
            .eq('id', userId)
            .single(),
      );

      final perfil = Perfiles.fromJson(response);

      Organizaciones? org;
      if (response['organizaciones'] != null) {
        org = Organizaciones.fromJson(response['organizaciones']);
      }

      return {'perfil': perfil, 'organizacion': org};
    } on PostgrestException catch (e) {
      throw Exception('Error cargando perfil: ${e.message}');
    } catch (e) {
      final msg = _friendlyNetworkMessage(e);
      throw Exception(msg ?? 'Error cargando perfil: $e');
    }
  }

  Future<User> createUser({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _withTransientNetworkRetry(
        () => supabase.auth.signUp(
          email: email,
          password: password,
          data: metadata,
        ),
      );
      final user = response.user;
      if (user == null) {
        throw Exception('No se obtuvo usuario al crear la cuenta');
      }
      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      final msg = _friendlyNetworkMessage(e);
      throw Exception(msg ?? 'Error creando usuario: $e');
    }
  }

  Future<User> createUserPreservingSession({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
    Future<void> Function(User user)? runWithNewUserSession,
  }) async {
    final prevSession = supabase.auth.currentSession;
    final prevPersisted =
        prevSession != null ? jsonEncode(prevSession.toJson()) : null;
    var restored = false;

    Future<void> restorePreviousSession() async {
      if (restored || prevPersisted == null) {
        restored = true;
        return;
      }
      await supabase.auth.signOut();
      await supabase.auth.recoverSession(prevPersisted);
      restored = true;
    }

    try {
      final response = await _withTransientNetworkRetry(
        () => supabase.auth.signUp(
          email: email,
          password: password,
          data: metadata,
        ),
      );
      final user = response.user;
      if (user == null) {
        throw Exception('No se obtuvo usuario al crear la cuenta');
      }

      if (runWithNewUserSession != null) {
        await runWithNewUserSession(user);
      }

      await restorePreviousSession();
      return user;
    } on AuthException catch (e) {
      await restorePreviousSession();
      throw Exception(e.message);
    } catch (e) {
      await restorePreviousSession();
      final msg = _friendlyNetworkMessage(e);
      throw Exception(msg ?? 'Error creando usuario: $e');
    }
  }

  static Future<T> _withTransientNetworkRetry<T>(
    Future<T> Function() fn, {
    int retries = 2,
    Duration initialDelay = const Duration(milliseconds: 600),
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        if (!_isTransientNetworkError(e) || attempt >= retries) rethrow;
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (attempt + 1),
        );
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }

  static bool _isTransientNetworkError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('network is unreachable') ||
        text.contains('connection reset') ||
        text.contains('connection refused') ||
        text.contains('timed out') ||
        text.contains('dns');
  }

  static String? _friendlyNetworkMessage(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('dns')) {
      return 'No se pudo conectar (DNS). Revisa tu Internet y vuelve a intentar.';
    }
    if (text.contains('network is unreachable') ||
        text.contains('timed out') ||
        text.contains('socketexception') ||
        text.contains('clientexception')) {
      return 'No se pudo conectar a Internet. Revisa tu conexión y vuelve a intentar.';
    }
    return null;
  }
}

