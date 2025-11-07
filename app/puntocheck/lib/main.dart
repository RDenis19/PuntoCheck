import 'package:flutter/material.dart';
import 'package:puntocheck/app.dart';
import 'package:puntocheck/data/datasources/firebase_auth_datasource.dart';
import 'package:puntocheck/data/datasources/firebase_storage_datasource.dart';
import 'package:puntocheck/data/datasources/firebase_user_datasource.dart';
import 'package:puntocheck/data/repositories/auth_repository.dart';
import 'package:puntocheck/domain/services/biometric_service.dart';
import 'package:puntocheck/domain/services/secure_storage_service.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  final authRepository = AuthRepository(
    authDatasource: FirebaseAuthDatasource(),
    userDatasource: FirebaseUserDatasource(),
    storageDatasource: FirebaseStorageDatasource(),
  );
  final biometricService = BiometricService();
  final secureStorageService = SecureStorageService();

  final authController = AuthController(
    authRepository: authRepository,
    biometricService: biometricService,
    secureStorageService: secureStorageService,
  );
  await authController.init();

  runApp(PuntoCheckApp(authController: authController));
}

class FirebaseBootstrap {
  static Future<void> initialize() async {
    // Aquí va Firebase.initializeApp()
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
