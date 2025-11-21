import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: const Center(
        child: Text(
          'El registro público está deshabilitado.\nContacte a su administrador para crear una cuenta.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
