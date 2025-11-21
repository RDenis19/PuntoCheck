import 'package:flutter/material.dart';
import 'package:puntocheck/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/services/supabase_client.dart';

/// Entrada principal de la aplicacion.
/// Inicializa Supabase usando variables de entorno `--dart-define`:
///  flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=key
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClient.initialize();
  runApp(
    const ProviderScope(
      child: PuntoCheckApp(),
    ),
  );
}

