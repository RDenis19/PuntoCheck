import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/frontend/rutas/app_router.dart';
import 'package:puntocheck/backend/config/provider_setup.dart';

class PuntoCheckApp extends StatelessWidget {
  const PuntoCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAuthProviders(),
      child: MaterialApp(
        title: 'PuntoCheck',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
