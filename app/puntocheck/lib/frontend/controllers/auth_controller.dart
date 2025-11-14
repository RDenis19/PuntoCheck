import 'dart:math';

import 'package:flutter/material.dart';
import 'package:puntocheck/core/utils/result.dart';
import 'package:puntocheck/backend/data/repositories/auth_repository.dart';
import 'package:puntocheck/backend/domain/entities/app_user.dart';
import 'package:puntocheck/backend/domain/services/biometric_service.dart';
import 'package:puntocheck/backend/domain/services/secure_storage_service.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';

// TODO(backend): este punto se conecta con backend usando backend/data o backend/domain.
// Motivo: desacoplar UI de la lógica de datos.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required BiometricService biometricService,
    required SecureStorageService secureStorageService,
  })  : _repository = authRepository,
        _biometricService = biometricService,
        _secureStorage = secureStorageService;

  final AuthRepository _repository;
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
      currentUser = await _repository.restoreSession(rememberedEmail!);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<Result<void>> login(String email, String password, {BuildContext? context}) async {
    _setLoading(true);
    try {
      final user = await _repository.login(email: email.trim(), password: password);
      currentUser = user;
      rememberedEmail = user.email;
      await _secureStorage.write(SecureStorageService.keyRememberedEmail, user.email);
      await _secureStorage.write(SecureStorageService.keySessionToken, _generateSessionToken());
      errorMessage = null;
      // Navegar según rol si se proporcionó el contexto
      if (context != null) _navigateAfterAuth(context, user);
      return Result.success();
    } catch (error) {
      errorMessage = error.toString();
      return Result.failure(errorMessage!);
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
      final user = await _repository.loginWithStoredSession(email);
      currentUser = user;
      await _secureStorage.write(SecureStorageService.keySessionToken, savedToken);
      errorMessage = null;
      return Result.success();
    } catch (error) {
      errorMessage = error.toString();
      return Result.failure(errorMessage!);
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
    BuildContext? context,
  }) async {
    _setLoading(true);
    try {
      final user = await _repository.register(
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
      if (context != null) _navigateAfterAuth(context, user);
      return Result.success();
    } catch (error) {
      errorMessage = error.toString();
      return Result.failure(errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  void _navigateAfterAuth(BuildContext context, AppUser user) {
    final role = (user.role ?? '').toLowerCase();
    switch (role) {
      case 'employee':
        Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
        return;
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRouter.adminHome);
        return;
      case 'superadmin':
        Navigator.pushReplacementNamed(context, AppRouter.superAdminHome);
        return;
      default:
        // Si no hay rol, redirige a employee por defecto
        Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
    }
  }

  Future<Result<void>> sendResetEmail(String email) async {
    _setLoading(true);
    try {
      await _repository.sendResetEmail(email.trim());
      return Result.success();
    } catch (error) {
      return Result.failure(error.toString());
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
      await _repository.updatePassword(newPassword);
      await _secureStorage.write(SecureStorageService.keySessionToken, _generateSessionToken());
      return Result.success();
    } catch (error) {
      return Result.failure(error.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    currentUser = null;
    await _secureStorage.delete(SecureStorageService.keySessionToken);
    notifyListeners();
  }

  String _generateSessionToken() => 'token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
}