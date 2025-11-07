import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final user = controller.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PuntoCheck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await controller.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: user == null
              ? const Center(child: Text('No hay sesión activa'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, ${user.nombreCompleto}', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(user.email),
                    Text(user.telefono),
                    if (user.fotoUrl != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(user.fotoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SwitchListTile.adaptive(
                      value: controller.biometricEnabled,
                      title: const Text('Habilitar biometría para este dispositivo'),
                      onChanged: controller.biometricAvailable
                          ? (value) async {
                              final result = await controller.enableBiometrics(value);
                              if (!context.mounted) {
                                return;
                              }
                              if (result.isFailure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.message ?? 'No se pudo actualizar la biometría')),
                                );
                              }
                            }
                          : null,
                      subtitle: Text(
                        controller.biometricAvailable
                            ? 'Usa huella o FaceID para el próximo inicio'
                            : 'Tu dispositivo no tiene sensores biométricos',
                      ),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Ir a control de asistencia',
                      onPressed: () {},
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
