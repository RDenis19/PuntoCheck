import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/widgets/primary_button.dart';

class ForgotPasswordCodePage extends StatefulWidget {
  const ForgotPasswordCodePage({super.key});

  @override
  State<ForgotPasswordCodePage> createState() => _ForgotPasswordCodePageState();
}

class _ForgotPasswordCodePageState extends State<ForgotPasswordCodePage> {
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goToReset() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('En producción se valida el enlace de Firebase. Aquí continuamos solo visualmente.'),
      ),
    );
    context.push('/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresa el código')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Introduce el código de 5 dígitos que llegó a tu correo'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (index) => SizedBox(
                    width: 52,
                    child: TextField(
                      controller: _controllers[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 4) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Verificar código', onPressed: _goToReset),
            ],
          ),
        ),
      ),
    );
  }
}
