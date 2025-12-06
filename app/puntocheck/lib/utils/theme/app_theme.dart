import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';
import 'package:puntocheck/utils/theme/brand_theme.dart';

class AppTheme {
  /// Construye ThemeData a partir de la paleta de marca seleccionada.
  static ThemeData fromBrand(BrandTheme brand) {
    final base = ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: brand.primary,
      brightness: Brightness.light,
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      secondary: brand.secondary,
      onSecondary: brand.onSecondary,
      surface: brand.surface,
      onSurface: brand.onSurface,
      error: brand.error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brand.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: brand.surface,
        foregroundColor: brand.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: brand.onSurface,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: brand.onSurface,
        displayColor: brand.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand.primary,
          foregroundColor: brand.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brand.secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: brand.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.neutral200),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brand.onBackground,
        contentTextStyle: TextStyle(color: brand.onPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
