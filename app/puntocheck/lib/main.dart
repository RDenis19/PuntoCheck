import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importación directa
import 'package:puntocheck/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicialización oficial de Supabase
  // Asegúrate de pasar tus keys reales o usar --dart-define como tenías planeado
  await Supabase.initialize(
    //url: const String.fromEnvironment('SUPABASE_URL'),
    url: 'https://vktmhhkddypnkxvexwqb.supabase.co',
    //anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZrdG1oaGtkZHlwbmt4dmV4d3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5NTI0NzYsImV4cCI6MjA4MDUyODQ3Nn0.SPKnAxS9UzTPlM0x-JPedUXQomzZy4FF9WgWiP0lNDE'
  );

  runApp(
    const ProviderScope(
      child: PuntoCheckApp(),
    ),
  );
}