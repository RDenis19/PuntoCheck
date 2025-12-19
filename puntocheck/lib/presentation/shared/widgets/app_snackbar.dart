import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Snackbar consistente para mensajes de éxito o error.
void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isError ? AppColors.errorRed : AppColors.neutral900,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}
