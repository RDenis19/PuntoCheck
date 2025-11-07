import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // Reemplaza estos valores con los de tu archivo google-services.json o firebase_options.dart
        apiKey: 'tu-api-key',
        appId: 'tu-app-id',
        messagingSenderId: 'tu-messaging-sender-id',
        projectId: 'tu-project-id',
        // Agrega storageBucket si vas a usar Firebase Storage
        storageBucket: 'tu-storage-bucket',
      ),
    );
  }
}