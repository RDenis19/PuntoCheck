import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/utils/secure_storage_helper.dart';

// TODO: Para producción, eliminar estas constantes y forzar el error si no vienen por --dart-define
// Por ahora, las dejamos para facilitar el desarrollo local si fallan los argumentos.
const _defaultSupabaseUrl = 'https://owpkipyvyqljqvsqqaiy.supabase.co';
const _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cGtpcHl2eXFsanF2c3FxYWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODI2NDEsImV4cCI6MjA4MTA1ODY0MX0.thq-BZelpDR1sjvvjIDm0ZeE-WGiNbT3VLNkg243NV8';

Future<void> main() async {
  // Asegura que el motor gráfico esté listo antes de llamar a servicios nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: _defaultSupabaseUrl,
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseAnonKey,
    ),
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  runApp(
    // ProviderScope es necesario para Riverpod
    const ProviderScope(child: PuntoCheckApp()),
  );
}
