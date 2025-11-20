import 'dart:math';

import 'package:flutter/material.dart';
import 'package:puntocheck/utils/result.dart';
import 'package:puntocheck/services/auth_service.dart';
import 'package:puntocheck/models/app_user.dart';
import 'package:puntocheck/services/biometric_service.dart';
import 'package:puntocheck/services/secure_storage_service.dart';

/// Provider que gestiona el estado de autenticación de la aplicación.
/// Intermediario entre la UI y los servicios de autenticación.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required BiometricService biometricService,
    required SecureStorageService secureStorageService,
  })  : _authService = authService,
        _biometricService = biometricService,
        _secureStorage = secureStorageService;

  final AuthService _authService;
  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;

  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  String? rememberedEmail;

  Future<void> init() async {
    biometricAvailable = await _biometricService.isBiometricAvailable();
    biometricEnabled = await _secureStorage.readFlag(SecureStorageService.keyBiometricEnabled);
    rememberedEmail = await _secureStorage.read(SecureStorageService.keyRememberedEmail);
    final storedToken = await _secureStorage.read(SecureStorageService.keySessionToken);
    if (storedToken != null && rememberedEmail != null) {
      currentUser = await _authService.restoreSession(rememberedEmail!);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<Result<void>> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.login(email: email.trim(), password: password);
      currentUser = user;
      rememberedEmail = user.email;
      await _secureStorage.write(SecureStorageService.keyRememberedEmail, user.email);
      await _secureStorage.write(SecureStorageService.keySessionToken, _generateSessionToken());
      errorMessage = null;
      return Result.success();
    } catch (error) {
      final friendly = _mapErrorToMessage(error);
      errorMessage = friendly;
      return Result.failure(friendly);
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<void>> loginWithBiometrics() async {
    if (!biometricAvailable || !biometricEnabled) {
      return Result.failure('Activa la biometría primero');
    }
    final email = rememberedEmail;
    final savedToken = await _secureStorage.read(SecureStorageService.keyBiometricSessionToken);
    if (email == null || savedToken == null) {
      return Result.failure('No hay sesión biométrica guardada');
    }
    _setLoading(true);
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        return Result.failure('No se pudo validar tu huella/FaceID');
      }
      final user = await _authService.loginWithStoredSession(email);
      currentUser = user;
      await _secureStorage.write(SecureStorageService.keySessionToken, savedToken);
      errorMessage = null;
      return Result.success();
    } catch (error) {
      final friendly = _mapErrorToMessage(error);
      errorMessage = friendly;
      return Result.failure(friendly);
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<void>> register({
    required String nombreCompleto,
    required String email,
    required String telefono,
    required String password,
    String? photoPath,
  }) async {
    _setLoading(true);
    try {
      final user = await _authService.register(
        nombreCompleto: nombreCompleto,
        email: email.trim(),
        telefono: telefono.trim(),
        password: password,
        photoPath: photoPath,
      );
      currentUser = user;
      rememberedEmail = user.email;
      await _secureStorage.write(SecureStorageService.keyRememberedEmail, user.email);
      await _secureStorage.write(SecureStorageService.keySessionToken, _generateSessionToken());
      errorMessage = null;
      return Result.success();
    } catch (error) {
      final friendly = _mapErrorToMessage(error);
      errorMessage = friendly;
      return Result.failure(friendly);
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<void>> sendResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendResetEmail(email.trim());
      return Result.success();
    } catch (error) {
      final friendly = _mapErrorToMessage(error);
      return Result.failure(friendly);
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<void>> enableBiometrics(bool enable, {String? email, String? password}) async {
    if (enable) {
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        return Result.failure('Tu dispositivo no soporta biometría');
      }
      final targetEmail = email ?? currentUser?.email;
      if (targetEmail == null) {
        return Result.failure('No hay usuario para vincular');
      }
      if (password != null && password.isNotEmpty) {
        // Por seguridad no persistimos la contraseña en esta demo.
      }
      // No guardamos la contraseña por seguridad, solo un token de sesión simulado.
      await _secureStorage.writeFlag(SecureStorageService.keyBiometricEnabled, true);
      await _secureStorage.write(SecureStorageService.keyRememberedEmail, targetEmail);
      await _secureStorage.write(SecureStorageService.keyBiometricSessionToken, _generateSessionToken());
      biometricEnabled = true;
      rememberedEmail = targetEmail;
      notifyListeners();
      return Result.success();
    } else {
      await _secureStorage.deleteKeys(<String>[
        SecureStorageService.keyBiometricEnabled,
        SecureStorageService.keyBiometricSessionToken,
      ]);
      biometricEnabled = false;
      notifyListeners();
      return Result.success();
    }
  }

  Future<Result<void>> updatePassword(String newPassword) async {
    _setLoading(true);
    try {
      if (currentUser == null) {
        return Result.failure('Debes usar el enlace del correo para finalizar el cambio');
      }
      await _authService.updatePassword(newPassword);
      await _secureStorage.write(SecureStorageService.keySessionToken, _generateSessionToken());
      return Result.success();
    } catch (error) {
      final friendly = _mapErrorToMessage(error);
      return Result.failure(friendly);
    } finally {
      _setLoading(false);
    }
  }

  String _mapErrorToMessage(Object? error) {
    final text = error?.toString() ?? 'Error desconocido';

    final lower = text.toLowerCase();

    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials') || lower.contains('credenciales inválidas') || lower.contains('invalid email or password') || lower.contains('wrong-password')) {
      return 'Correo o contraseña incorrectos';
    }

    if (lower.contains('user not found') || lower.contains('no se pudo encontrar') || lower.contains('not found')) {
      return 'No existe una cuenta con ese correo';
    }

    if (lower.contains('failed host lookup') || lower.contains('socketexception') || lower.contains('network')) {
      return 'Sin conexión. Revisa tu conexión a Internet';
    }

    if (lower.contains('invalid')) {
      return 'Entrada inválida. Revisa los datos ingresados';
    }

    // Fallback: devuelve el mensaje original pero más corto
    // Quitar prefijos de excepciones comunes (AuthApiException(...))
    final cleaned = text.replaceAll(RegExp(r'^.*?:\s*'), '');
    return cleaned;
  }

  Future<void> logout() async {
    currentUser = null;
    await _secureStorage.delete(SecureStorageService.keySessionToken);
    notifyListeners();
  }

  String _generateSessionToken() => 'token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
}