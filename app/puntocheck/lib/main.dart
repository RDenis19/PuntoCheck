import 'package:flutter/material.dart';
import 'package:puntocheck/app.dart';
import 'package:puntocheck/core/utils/supabase_bootstrap.dart';

/// Entrada principal de la aplicacion.
/// Inicializa Supabase usando variables de entorno `--dart-define`:
///  flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=key
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const PuntoCheckApp());
}

