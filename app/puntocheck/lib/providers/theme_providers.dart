import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/theme/app_theme.dart';
import '../utils/theme/brand_theme.dart';

// ============================================================================
// Branding y theming
// ============================================================================
class BrandThemeController extends StateNotifier<BrandTheme> {
  BrandThemeController() : super(BrandTheme.red());

  void applyPrimary(Color primary, {Color? onPrimary}) {
    state = state.copyWith(primary: primary, onPrimary: onPrimary);
  }

  void applyOrgPalette({
    required Color primary,
    Color? secondary,
    Color? onPrimary,
    Color? onSecondary,
  }) {
    state = state.copyWith(
      primary: primary,
      onPrimary: onPrimary ?? state.onPrimary,
      secondary: secondary ?? state.secondary,
      onSecondary: onSecondary ?? state.onSecondary,
    );
  }

  void resetToDefault() {
    state = BrandTheme.red();
  }
}

final brandThemeProvider =
    StateNotifierProvider<BrandThemeController, BrandTheme>(
      (ref) => BrandThemeController(),
    );

/// ThemeData consumido por MaterialApp con la paleta activa.
final appThemeProvider = Provider<ThemeData>((ref) {
  final brand = ref.watch(brandThemeProvider);
  return AppTheme.fromBrand(brand);
});
