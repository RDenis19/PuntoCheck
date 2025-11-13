import 'package:flutter/material.dart';

/// Widget que muestra un logo circular desde assets.
/// Usado en splash y pantallas de autenticación.
class CircleLogoAsset extends StatelessWidget {
  const CircleLogoAsset({
    super.key,
    this.size = 120,
    this.assetPath,
  });

  final double size;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: assetPath != null && assetPath!.isNotEmpty
            ? Image.asset(
                assetPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8313B),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}