import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/models/enums.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    // Esperar animacion minima
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Verificar sesion
    // Leemos el estado actual de auth
    final authState = await ref.read(authStateProvider.future);
    final user = authState.session?.user;

    if (user == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    try {
      final profile = await ref.read(profileProvider.future);
      if (!mounted) return;
      final role = profile?.rol ?? RolUsuario.employee;

      switch (role) {
        case RolUsuario.superAdmin:
          context.go(AppRoutes.superAdminHome);
          break;
        case RolUsuario.orgAdmin:
          context.go(AppRoutes.orgAdminHome);
          break;
        case RolUsuario.manager:
          context.go(AppRoutes.managerHome);
          break;
        case RolUsuario.auditor:
          context.go(AppRoutes.auditorHome);
          break;
        case RolUsuario.employee:
          context.go(AppRoutes.employeeHome);
          break;
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: ScaleTransition(
              scale: _scale,
              child: SizedBox(
                width: 200,
                child: Image.asset(
                  'assets/puntocheck_rojo_splash.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


