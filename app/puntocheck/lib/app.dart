import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/utils/theme/app_theme.dart';

// Importa el provider del router que definimos en routes/app_router.dart
import 'package:puntocheck/routes/app_router.dart'; 

class PuntoCheckApp extends ConsumerWidget {
  const PuntoCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observamos el GoRouter configurado con Riverpod
    final appRouter = ref.watch(appRouterProvider);

    // 2. Usamos el constructor .router de MaterialApp
    return MaterialApp.router(
      title: 'PuntoCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // 3. Delegamos toda la configuración de rutas a GoRouter
      routerConfig: appRouter,
    );
  }
}