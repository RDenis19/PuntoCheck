import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

/// Define la paleta dinámica que puede ajustar el admin de la organización.
/// Solo se cambia el primario/acentos; los neutros mantienen el contraste.
class BrandTheme {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color onBackground;
  final Color onSurface;
  final Color success;
  final Color warning;
  final Color info;
  final Color error;

  const BrandTheme({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.onBackground,
    required this.onSurface,
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
  });

  factory BrandTheme.red() {
    return const BrandTheme(
      primary: AppColors.primaryRed,
      onPrimary: AppColors.secondaryWhite,
      secondary: AppColors.secondaryWhite,
      onSecondary: AppColors.neutral900,
      background: AppColors.neutral100,
      surface: AppColors.secondaryWhite,
      onBackground: AppColors.neutral900,
      onSurface: AppColors.neutral900,
      success: AppColors.successGreen,
      warning: AppColors.warningOrange,
      info: AppColors.infoBlue,
      error: AppColors.errorRed,
    );
  }

  BrandTheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? surface,
    Color? onBackground,
    Color? onSurface,
    Color? success,
    Color? warning,
    Color? info,
    Color? error,
  }) {
    return BrandTheme(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      error: error ?? this.error,
    );
  }
}
