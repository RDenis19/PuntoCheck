import 'package:puntocheck/backend/data/datasources/supabase_auth_datasource.dart';
import 'package:puntocheck/backend/data/datasources/supabase_storage_datasource.dart';
import 'package:puntocheck/backend/data/datasources/supabase_user_datasource.dart';
import 'package:puntocheck/backend/data/models/user_model.dart';
import 'package:puntocheck/backend/domain/entities/app_user.dart';

class AuthRepository {
  AuthRepository({
    required this.authDatasource,
    required this.userDatasource,
    required this.storageDatasource,
  });

  final SupabaseAuthDatasource authDatasource;
  final SupabaseUserDatasource userDatasource;
  final SupabaseStorageDatasource storageDatasource;

  Future<AppUser> login({required String email, required String password}) async {
    final uid = await authDatasource.signIn(email, password);
    final user = await userDatasource.getUser(uid);
    if (user == null) {
      throw Exception('Usuario sin perfil en Firestore');
    }
    return user;
  }

  Future<AppUser> loginWithStoredSession(String email) async {
    final user = await userDatasource.getUserByEmail(email);
    if (user == null) {
      throw Exception('No se encontró una sesión guardada');
    }
    authDatasource.resumeSession(user.id);
    return user;
  }

  Future<AppUser?> restoreSession(String email) async {
    final user = await userDatasource.getUserByEmail(email);
    if (user == null) {
      return null;
    }
    authDatasource.resumeSession(user.id);
    return user;
  }

  Future<AppUser> register({
    required String nombreCompleto,
    required String email,
    required String telefono,
    required String password,
    String? photoPath,
  }) async {
    // Create the auth user and pass `full_name` in user metadata so
    // the DB trigger `handle_new_user` can populate `profiles`.
    final uid = await authDatasource.signUp(
      email,
      password,
      userMetadata: {'full_name': nombreCompleto},
    );
    final now = DateTime.now();
    final fotoUrl = await storageDatasource.uploadProfilePhoto(uid, localPath: photoPath);
    final user = UserModel(
      id: uid,
      nombreCompleto: nombreCompleto,
      email: email,
      telefono: telefono,
      fotoUrl: fotoUrl,
      createdAt: now,
      updatedAt: now,
    );
    // If the trigger already created a profile for this user, don't insert again.
    final existing = await userDatasource.getUser(uid);
    if (existing == null) {
      await userDatasource.createUser(user);
    }
    return user;
  }

  Future<void> sendResetEmail(String email) => authDatasource.sendResetEmail(email);

  Future<void> logout() async => await authDatasource.signOut();

  Future<void> refreshSession() async => await authDatasource.refreshSession();

  Future<void> updatePassword(String newPassword) async {
    final uid = authDatasource.currentUserId;
    if (uid == null) {
      throw Exception('Debes iniciar sesión primero');
    }
    await authDatasource.updatePassword(uid, newPassword);
  }

  String? get currentUserId => authDatasource.currentUserId;
}
