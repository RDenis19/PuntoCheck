import 'package:flutter/material.dart';
import 'package:puntocheck/frontend/widgets/primary_button.dart';

/// Wrapper de botones reutilizables para formularios de autenticación.
class AuthButtons {
  /// Botón primario para acciones principales (Login, Register, etc.)
  static Widget primary({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
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