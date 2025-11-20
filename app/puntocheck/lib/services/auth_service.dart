import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/models/user_model.dart';

/// Servicio de autenticación que encapsula toda la comunicación con Supabase
/// para operaciones de autenticación y gestión de usuarios.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ========== AUTENTICACIÓN ==========

  /// Inicia sesión con email y contraseña
  Future<UserModel> login({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Credenciales inválidas');
    }
    
    // Obtener el perfil del usuario desde la tabla profiles
    final userProfile = await getUser(user.id);
    if (userProfile == null) {
      throw Exception('Usuario sin perfil en la base de datos');
    }
    return userProfile;
  }

  /// Registra un nuevo usuario
  Future<UserModel> register({
    required String nombreCompleto,
    required String email,
    required String telefono,
    required String password,
    String? photoPath,
  }) async {
    // Crear el usuario en auth con metadata
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': nombreCompleto},
    );
    final user = res.user;
    if (user == null) {
      throw Exception('No se pudo crear la cuenta');
    }

    final now = DateTime.now();
    String? fotoUrl;
    
    // Subir foto de perfil si se proporciona
    if (photoPath != null) {
      fotoUrl = await uploadProfilePhoto(user.id, localPath: photoPath);
    }

    final userModel = UserModel(
      id: user.id,
      nombreCompleto: nombreCompleto,
      email: email,
      telefono: telefono,
      fotoUrl: fotoUrl,
      createdAt: now,
      updatedAt: now,
    );

    // Verificar si el trigger ya creó el perfil
    final existing = await getUser(user.id);
    if (existing == null) {
      await createUser(userModel);
    }

    return userModel;
  }

  /// Inicia sesión con sesión guardada
  Future<UserModel> loginWithStoredSession(String email) async {
    final user = await getUserByEmail(email);
    if (user == null) {
      throw Exception('No se encontró una sesión guardada');
    }
    return user;
  }

  /// Restaura sesión existente
  Future<UserModel?> restoreSession(String email) async {
    final user = await getUserByEmail(email);
    return user;
  }

  /// Envía email para restablecer contraseña
  Future<void> sendResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Actualiza la contraseña del usuario actual
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Cierra sesión
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Refresca la sesión actual
  Future<void> refreshSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return;
      await _client.auth.refreshSession();
    } catch (_) {
      // ignore
    }
  }

  /// ID del usuario actual
  String? get currentUserId => _client.auth.currentUser?.id;

  // ========== GESTIÓN DE USUARIOS ==========

  /// Crea un nuevo perfil de usuario en la tabla profiles
  Future<void> createUser(UserModel user) async {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(user.toMap());

    // Remover campos que ya están en auth.users
    payload.remove('email');
    payload.remove('created_at');
    payload.remove('updated_at');

    try {
      await _client.from('profiles').insert(payload).select().maybeSingle();
    } catch (e) {
      throw Exception('Error inserting profile into profiles: $e');
    }
  }

  /// Obtiene un usuario por su ID
  Future<UserModel?> getUser(String uid) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  /// Obtiene un usuario por su email
  Future<UserModel?> getUserByEmail(String email) async {
    final data = await _client
        .from('profiles')
        .select()
        .ilike('email', email)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  /// Actualiza un perfil de usuario
  Future<void> updateUser(UserModel user) async {
    await _client.from('profiles').update(user.toMap()).eq('id', user.id);
  }

  // ========== ALMACENAMIENTO ==========

  /// Sube una foto de perfil al storage de Supabase
  Future<String?> uploadProfilePhoto(String userId, {String? localPath}) async {
    if (localPath == null || localPath.isEmpty) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId-$timestamp.jpg';
      final storagePath = 'profiles/$fileName';

      // Convertir el path a File
      final file = File(localPath);
      await _client.storage.from('avatars').upload(storagePath, file);

      final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir la foto de perfil: $e');
    }
  }
}
