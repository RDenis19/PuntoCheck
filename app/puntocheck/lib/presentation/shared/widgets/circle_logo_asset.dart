import 'package:flutter/material.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class CircleLogoAsset extends StatelessWidget {
  const CircleLogoAsset({super.key, this.radius = 60});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: AppColors.neutral900,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/puntocheck_rojo_splash.png',
          height: radius,
        ),
      ),
    );
  }
}
