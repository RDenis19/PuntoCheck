import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:puntocheck/services/auth_service.dart';
import 'package:puntocheck/services/biometric_service.dart';
import 'package:puntocheck/services/secure_storage_service.dart';
import 'package:puntocheck/providers/auth_provider.dart';

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
    // Servicio de autenticación
    Provider<AuthService>(
      create: (_) => AuthService(),
    ),
    // Provider principal (ChangeNotifier para notificaciones de cambios)
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        authService: context.read<AuthService>(),
        biometricService: context.read<BiometricService>(),
        secureStorageService: context.read<SecureStorageService>(),
      ),
    ),
  ];
}
