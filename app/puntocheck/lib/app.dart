import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/utils/theme/app_theme.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/providers/provider_setup.dart';

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

