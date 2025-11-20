import 'package:flutter/material.dart';
import 'package:puntocheck/presentation/shared/widgets/primary_button.dart';

/// Wrapper de botones reutilizables para formularios de autenticación.
class AuthButtons {
  /// Botón primario para acciones principales (Login, Register, etc.)
  static Widget primary({
    required String label,
    required VoidCallback onPressed,
  }) {
    return PrimaryButton(
      text: label,
      onPressed: onPressed,
    );
  }

  /// Botón de texto para acciones secundarias (links)
  static Widget textButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8313B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
