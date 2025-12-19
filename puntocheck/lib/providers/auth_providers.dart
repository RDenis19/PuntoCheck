import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enums.dart';
import '../models/perfiles.dart';
import 'core_providers.dart';

// ============================================================================
// Auth y perfil
// ============================================================================
/// Stream del estado de autenticacion (login/logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Usuario actual (nullable).
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value.session?.user ?? auth.currentUser;
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(email, password),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

final profileProvider = FutureProvider<Perfiles?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final auth = ref.watch(authServiceProvider);
  final session = authState.asData?.value.session ?? auth.currentSession;
  final user = session?.user;
  if (user == null) return null;
  final result = await auth.getFullUserProfile();
  return result['perfil'] as Perfiles?;
});

final userRoleProvider = Provider<RolUsuario?>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.asData?.value?.rol;
});

/// Indicador para saltar redirecciones breves mientras se preserva la sesión
/// original (por ejemplo al crear empleados sin cerrar la sesión actual).
final authSessionTransitionProvider = StateProvider<bool>((_) => false);
