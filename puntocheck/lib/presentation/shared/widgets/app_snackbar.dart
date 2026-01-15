import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  // 1. LIMPIEZA AUTOMÁTICA DE ERRORES TÉCNICOS
  // Esta es la parte que "intercepta" el texto feo
  String cleanMessage = message;

  if (message.contains('SocketException') || 
      message.contains('Failed host lookup') || 
      message.contains('ClientException') ||
      message.contains('Connection refused') ||
      message.contains('Network is unreachable')) {
    cleanMessage = '⚠️ No tienes conexión a internet. Verifica tu red e intenta de nuevo.';
  } else if (message.contains('timeout')) {
    cleanMessage = '⏳ La conexión está muy lenta. Intenta de nuevo.';
  } else if (message.contains('AuthException')) {
    cleanMessage = '🔒 Tu sesión ha expirado. Ingresa nuevamente.';
  } else if (message.contains('Exception:')) {
    // Limpia el prefijo técnico "Exception:"
    cleanMessage = message.replaceAll('Exception: ', '').trim();
  }

  // Si el mensaje sigue teniendo "Error: Error: ...", lo limpiamos
  if (cleanMessage.startsWith('Error: ')) {
    cleanMessage = cleanMessage.substring(7);
  }

  // 2. MOSTRAR EL SNACKBAR MEJORADO
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        cleanMessage,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      // Si es error de internet, usamos naranja/rojo, si es éxito verde
      backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: duration,
    ),
  );
}