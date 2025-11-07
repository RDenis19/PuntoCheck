import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/core/theme/app_theme.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/routes/app_router.dart';

class PuntoCheckApp extends StatefulWidget {
  const PuntoCheckApp({super.key, required this.authController});

  final AuthController authController;

  @override
  State<PuntoCheckApp> createState() => _PuntoCheckAppState();
}

class _PuntoCheckAppState extends State<PuntoCheckApp> {
  late final AppRouter _router = AppRouter(widget.authController);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>.value(
      value: widget.authController,
      child: MaterialApp.router(
        title: 'PuntoCheck',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router.router,
      ),
    );
  }
}
