import 'package:puntocheck/backend/data/datasources/firebase_auth_datasource.dart';
import 'package:puntocheck/backend/data/datasources/firebase_storage_datasource.dart';
import 'package:puntocheck/backend/data/datasources/firebase_user_datasource.dart';
import 'package:puntocheck/backend/data/models/user_model.dart';
import 'package:puntocheck/backend/domain/entities/app_user.dart';

class AuthRepository {
  AuthRepository({
    required this.authDatasource,
    required this.userDatasource,
    required this.storageDatasource,
  });

  final FirebaseAuthDatasource authDatasource;
  final FirebaseUserDatasource userDatasource;
  final FirebaseStorageDatasource storageDatasource;

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
    final uid = await authDatasource.signUp(email, password);
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
    await userDatasource.createUser(user);
    return user;
  }

  Future<void> sendResetEmail(String email) => authDatasource.sendResetEmail(email);

  Future<void> updatePassword(String newPassword) async {
    final uid = authDatasource.currentUserId;
    if (uid == null) {
      throw Exception('Debes iniciar sesión primero');
    }
    await authDatasource.updatePassword(uid, newPassword);
  }

  String? get currentUserId => authDatasource.currentUserId;
}
