import 'package:flutter/material.dart';

class AppColors {
  // Paleta base (rojo + blanco). El admin de la organización puede sobreescribir
  // el rojo con otro primario sin romper el contraste porque tenemos neutrales.
  static const Color primaryRed = Color(0xFFE0262F);
  static const Color primaryRedDark = Color(0xFFC01F28);
  static const Color secondaryWhite = Color(0xFFFFFFFF);

  // Neutros para backgrounds y bordes.
  static const Color neutral100 = Color(0xFFF7F8FA);
  static const Color neutral200 = Color(0xFFF0F1F4);
  static const Color neutral500 = Color(0xFF9BA2AE);
  static const Color neutral600 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFFCDD1D9);
  static const Color neutral700 = Color(0xFF2E3238);
  static const Color neutral900 = Color(0xFF121418);
  static const Color white = secondaryWhite;
  static const Color black = Color(0xFF000000);

  // Estados y semánticos.
  static const Color successGreen = Color(0xFF1ABC9C);
  static const Color warningOrange = Color(0xFFF5A623);
  static const Color infoBlue = Color(0xFF1E88E5);
  static const Color errorRed = Color(0xFFD7263D);
}
