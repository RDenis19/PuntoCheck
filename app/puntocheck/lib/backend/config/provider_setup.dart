import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:puntocheck/backend/data/datasources/supabase_auth_datasource.dart';
import 'package:puntocheck/backend/data/datasources/supabase_storage_datasource.dart';
import 'package:puntocheck/backend/data/datasources/supabase_user_datasource.dart';
import 'package:puntocheck/backend/data/repositories/auth_repository.dart';
import 'package:puntocheck/backend/domain/services/biometric_service.dart';
import 'package:puntocheck/backend/domain/services/secure_storage_service.dart';
import 'package:puntocheck/frontend/features/auth/controllers/auth_controller.dart';

/// Configura todos los providers necesarios para la aplicación.
/// Retorna una lista de providers para envolver MaterialApp con MultiProvider.
List<SingleChildWidget> buildAuthProviders() {
  return <SingleChildWidget>[
    // Servicio de almacenamiento seguro
    Provider<SecureStorageService>(
      create: (_) => SecureStorageService(),
    ),
    // Servicio de biometría
    Provider<BiometricService>(
      create: (_) => BiometricService(),
    ),
    // Datasources
    Provider<SupabaseAuthDatasource>(
      create: (_) => SupabaseAuthDatasource(),
    ),
    Provider<SupabaseUserDatasource>(
      create: (_) => SupabaseUserDatasource(),
    ),
    Provider<SupabaseStorageDatasource>(
      create: (_) => SupabaseStorageDatasource(),
    ),
    // Repositorio
    Provider<AuthRepository>(
      create: (context) => AuthRepository(
        authDatasource: context.read<SupabaseAuthDatasource>(),
        userDatasource: context.read<SupabaseUserDatasource>(),
        storageDatasource: context.read<SupabaseStorageDatasource>(),
      ),
    ),
    // Controlador principal (ChangeNotifier para notificaciones de cambios)
    ChangeNotifierProvider<AuthController>(
      create: (context) => AuthController(
        authRepository: context.read<AuthRepository>(),
        biometricService: context.read<BiometricService>(),
        secureStorageService: context.read<SecureStorageService>(),
      ),
    ),
  ];
}

