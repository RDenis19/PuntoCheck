import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool success = true,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
    ),
  );
}
