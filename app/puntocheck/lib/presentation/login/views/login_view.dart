import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/presentation/login/views/device_setup_view.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';
import 'package:puntocheck/utils/device_identity.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _hasNavigated = false;
  bool _loadingDeviceId = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openDeviceSetup() async {
    if (_loadingDeviceId) return;
    setState(() => _loadingDeviceId = true);
    try {
      if (!mounted) return;
      // Inicializa/garantiza que exista un Device ID antes de abrir la pantalla.
      await getDeviceIdentity();
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(builder: (_) => const DeviceSetupView()));
    } finally {
      if (mounted) setState(() => _loadingDeviceId = false);
    }
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa email y contrasena')),
      );
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).signIn(email, password);
    } catch (e, st) {
      // ignore: avoid_print
      print('LOGIN signIn error: $e\n$st');
    }

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error.toString())));
      return;
    }

    await _redirectByRole();
  }

  Future<void> _redirectByRole() async {
    if (_hasNavigated) return;
    try {
      final profile = await ref.refresh(profileProvider.future);
      if (!mounted) return;
      final role = profile?.rol;
      if (role == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontrケ un rol para este usuario'),
          ),
        );
        context.go(AppRoutes.splash);
        return;
      }
      _hasNavigated = true;
      // ignore: use_build_context_synchronously
      context.go(AppRoutes.homeForRole(role));
    } catch (e, st) {
      // ignore: avoid_print
      print('LOGIN redirect error: $e\n$st');
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.go(AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha cambios de auth durante el build (uso permitido) para redirigir si ya hay sesion.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final session = next.asData?.value.session;
      if (session != null && !_hasNavigated) {
        _redirectByRole();
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bienvenido a PuntoCheck',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesion para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextFieldIcon(
                controller: _emailController,
                hintText: 'Correo electronico',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFieldIcon(
                controller: _passwordController,
                hintText: 'Contrasena',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Iniciar Sesion',
                isLoading: isLoading,
                onPressed: _onLogin,
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _loadingDeviceId ? null : _openDeviceSetup,
                icon: _loadingDeviceId
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.phonelink_setup_outlined),
                label: const Text('Configurar dispositivo (kiosko)'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
