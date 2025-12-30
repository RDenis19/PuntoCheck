import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importación directa

const _defaultSupabaseUrl = 'https://owpkipyvyqljqvsqqaiy.supabase.co';
const _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93cGtpcHl2eXFsanF2c3FxYWl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODI2NDEsImV4cCI6MjA4MTA1ODY0MX0.thq-BZelpDR1sjvvjIDm0ZeE-WGiNbT3VLNkg243NV8';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización oficial de Supabase
  // Asegúrate de pasar tus keys reales o usar --dart-define como tenías planeado
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: _defaultSupabaseUrl,
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseAnonKey,
    ),
  );

  runApp(const ProviderScope(child: PuntoCheckApp()));
}
