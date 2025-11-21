import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/routes/app_router.dart';
import 'package:puntocheck/providers/auth_provider.dart';
import 'package:puntocheck/providers/biometric_provider.dart';
import 'package:puntocheck/presentation/shared/widgets/circle_logo_asset.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';
import 'package:puntocheck/presentation/shared/widgets/text_field_icon.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Mock credentials for dev
    // Mock credentials removed
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa email y contraseña')),
      );
      return;
    }

    // Trigger login
    await ref.read(authControllerProvider.notifier).signIn(email, password);
    
    // Check result
    final state = ref.read(authControllerProvider);
    
    if (state.hasError) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
      return;
    }

    // Success - Navigate based on role
    // We need to fetch the profile to know the role
    // The profile provider should update automatically after login
    // But we might need to wait a bit or check the provider directly
    
    // Wait for profile to be loaded?
    // Actually, let's just navigate to a loading/intermediate screen or check profile
    // For now, simple navigation based on profile
    
    // Force refresh profile just in case?
    // ref.refresh(currentUserProfileProvider);
    
    // We can listen to the profile provider in the build method or here
    // But since we are in an async method, let's just get the value
    final profileAsync = await ref.read(currentUserProfileProvider.future);
    
    if (!mounted) return;

    if (profileAsync == null) {
       // Fallback if profile creation failed or not found
       Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
       return;
    }

    if (profileAsync.isSuperAdmin) {
      Navigator.pushReplacementNamed(context, AppRouter.superAdminHome);
    } else if (profileAsync.isOrgAdmin) {
      Navigator.pushReplacementNamed(context, AppRouter.adminHome);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.employeeHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const CircleLogoAsset(),
              const SizedBox(height: 20),
              const Text(
                'PuntoCheck',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control de Asistencia',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 40),
              TextFieldIcon(
                controller: _emailController,
                hintText: 'Correo Electrónico',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFieldIcon(
                controller: _passwordController,
                hintText: 'Contraseña',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.forgotEmail);
                  },
                  child: Text(
                    '¿Olvidaste Contraseña?',
                    style: TextStyle(color: Colors.indigo.shade400),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: isLoading ? 'Ingresando...' : 'Iniciar Sesión',
                enabled: !isLoading,
                onPressed: _onLogin,
              ),
              const SizedBox(height: 8),
              // Mock info removed
              // Debug buttons removed
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'o',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  // Verificar si biometría está disponible
                  final isAvailable = await ref.read(isBiometricAvailableProvider.future);
                  
                  if (!mounted) return;
                  
                  if (!isAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Autenticación biométrica no disponible en este dispositivo.'),
                      ),
                    );
                    return;
                  }
                  
                  // Ejecutar autenticación biométrica
                  final success = await ref.read(biometricControllerProvider.notifier).authenticate();
                  
                  if (!mounted) return;
                  
                  if (success) {
                    // Si la biometría fue exitosa, cargar credenciales guardadas
                    // Por ahora, mostramos mensaje de éxito
                    // TODO: Implementar guardado seguro de credenciales con flutter_secure_storage
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Autenticación biométrica exitosa. Implementar carga de credenciales.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Autenticación biométrica fallida o cancelada.'),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed.withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fingerprint,
                        color: AppColors.primaryRed,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Usar Autentificación Biométrica'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*
                  Text(
                    '¿Nuevo usuario? ',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.register);
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  */
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
